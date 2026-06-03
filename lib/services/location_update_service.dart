import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/login_controller.dart';
import 'api_service.dart';

/// Cross-platform background location service.
/// Android : flutter_background_service (foreground service + Timer)
/// iOS     : Native CLLocationManager via AppDelegate MethodChannel
///           → location updates sent directly from native side
///           → no Dart Timer needed (Timer is suspended in iOS background)
class LocationUpdateService extends GetxService {
  // ── Android ───────────────────────────────────────────────────────────────
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();

  // ── iOS native channel ────────────────────────────────────────────────────
  static const _channel = MethodChannel('com.mayfair.location');

  // ── iOS state ─────────────────────────────────────────────────────────────
  String? _iosToken;
  int?    _iosActiveTripId;
  DateTime _iosLastSent = DateTime.fromMillisecondsSinceEpoch(0);

  int? _activeTripId;

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _backgroundService.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'driver_location_channel',
          initialNotificationTitle: 'Mayfair Driver',
          initialNotificationContent: 'Location tracking active',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
    }

    if (Platform.isIOS) {
      // Register channel handler immediately at app start
      _channel.setMethodCallHandler(_handleNativeMethodCall);
      debugPrint('iOS: channel handler registered');
    }
  }

  // ── Ping native to verify channel works ──────────────────────────────────
  Future<void> _verifyChannel() async {
    try {
      final result = await _channel.invokeMethod<bool>('startBackgroundLocation');
      debugPrint('iOS: channel ping result = $result');
    } catch (e) {
      debugPrint('iOS: channel ping error = $e');
    }
  }

  // ── Handle native → Dart calls ────────────────────────────────────────────
  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onLocationUpdate') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      final lat  = (data['latitude']  as num).toDouble();
      final lng  = (data['longitude'] as num).toDouble();

      // Sync _iosActiveTripId with _activeTripId (in case setActiveTripId
      // was called before _startIos set _iosActiveTripId)
      _iosActiveTripId ??= _activeTripId;

      debugPrint('iOS native location received: \$lat, \$lng | tripId: \$_iosActiveTripId | token: \${_iosToken != null ? "set" : "null"}');

      if (_iosToken == null || _iosToken!.isEmpty) {
        // Try to get token from LoginController
        try {
          final token = Get.find<LoginController>().authToken.value;
          if (token.isNotEmpty) {
            _iosToken = token;
            debugPrint('iOS: token recovered from LoginController');
          } else {
            debugPrint('iOS: token empty — skipping send');
            return;
          }
        } catch (e) {
          debugPrint('iOS: cannot get token — $e');
          return;
        }
      }

      if (_iosActiveTripId == null) {
        debugPrint('iOS: no active trip — skipping API send');
        return;
      }

      // Throttle — send to API at most every 25 seconds
      final now = DateTime.now();
      if (now.difference(_iosLastSent).inSeconds < 25) {
        debugPrint('iOS: throttled — skipping send');
        return;
      }
      _iosLastSent = now;

      await _sendLocationToApi(
        token: _iosToken!,
        latitude: lat,
        longitude: lng,
        tripId: _iosActiveTripId,
      );
      debugPrint('iOS sent location to API: $lat, $lng — trip: $_iosActiveTripId');
    }
  }

  // ── Set active trip ───────────────────────────────────────────────────────
  Future<void> setActiveTripId(int? tripId) async {
    _activeTripId = tripId;

    if (Platform.isAndroid) {
      if (await _backgroundService.isRunning()) {
        _backgroundService.invoke('setTripId', {'tripId': tripId});
      }
    } else if (Platform.isIOS) {
      _iosActiveTripId = tripId;
      debugPrint('iOS LocationService: tripId set to $tripId');

      if (tripId == null) {
        // Trip ended — stop native location updates
        try {
          await _channel.invokeMethod('stopBackgroundLocation');
        } catch (e) {
          debugPrint('iOS stop native error: $e');
        }
        _iosFallbackTimer?.cancel();
        _iosFallbackTimer = null;
        debugPrint('iOS LocationService: trip ended — native location stopped');
      } else {
        // New trip started — ensure native location is running
        try {
          await _channel.invokeMethod('startBackgroundLocation');
        } catch (e) {
          debugPrint('iOS start native error: $e');
        }
      }
    }
  }

  // ── Start ─────────────────────────────────────────────────────────────────
  Future<void> start() async {
    final token = Get.find<LoginController>().authToken.value;
    if (token.isEmpty) return;

    await _requestPermissions();

    if (Platform.isAndroid) {
      await _startAndroid(token);
    } else if (Platform.isIOS) {
      await _startIos(token);
    }
  }

  // ── Android start ─────────────────────────────────────────────────────────
  Future<void> _startAndroid(String token) async {
    await _backgroundService.startService();
    _backgroundService.invoke('setToken', {'token': token});
    if (_activeTripId != null) {
      _backgroundService.invoke('setTripId', {'tripId': _activeTripId});
    }
  }

  // ── iOS fallback timer ───────────────────────────────────────────────────
  Timer? _iosFallbackTimer;

  // ── iOS start ─────────────────────────────────────────────────────────────
  Future<void> _startIos(String token) async {
    _iosToken = token;
    _iosActiveTripId = _activeTripId;

    // Re-register channel handler in case it was reset
    _channel.setMethodCallHandler(_handleNativeMethodCall);
    debugPrint('iOS: channel handler re-registered in _startIos');

    // Start native CLLocationManager via AppDelegate
    try {
      final result = await _channel.invokeMethod<bool>('startBackgroundLocation');
      debugPrint('iOS native CLLocationManager started — result: $result');
    } catch (e) {
      debugPrint('iOS native start error: $e');
    }

    // Fallback timer — every 30s request fresh position via geolocator
    // This ensures updates even when device hasn't moved (distanceFilter)
    _iosFallbackTimer?.cancel();
    _iosFallbackTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_iosToken == null || _iosActiveTripId == null) return;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));

        final now = DateTime.now();
        if (now.difference(_iosLastSent).inSeconds < 25) return;
        _iosLastSent = now;

        await _sendLocationToApi(
          token: _iosToken!,
          latitude: position.latitude,
          longitude: position.longitude,
          tripId: _iosActiveTripId,
        );
        debugPrint('iOS fallback timer sent: ${position.latitude}, ${position.longitude} — trip: $_iosActiveTripId');
      } catch (e) {
        debugPrint('iOS fallback timer error: $e');
      }
    });
  }

  // ── Stop ──────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    _activeTripId = null;

    if (Platform.isAndroid) {
      _backgroundService.invoke('stopService');
    } else if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('stopBackgroundLocation');
      } catch (e) {
        debugPrint('iOS stop native error: $e');
      }
      _iosFallbackTimer?.cancel();
      _iosFallbackTimer = null;
      _iosToken           = null;
      _iosActiveTripId    = null;
      debugPrint('iOS LocationService stopped');
    }
  }

  // ── Permissions ───────────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    // Notification — show disclosure dialog only once
    final notifShown = prefs.getBool('notif_dialog_shown') ?? false;
    if (!notifShown && await Permission.notification.isDenied) {
      await _showNotificationDisclosureDialog();
      await prefs.setBool('notif_dialog_shown', true);
      await Permission.notification.request();
    } else if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Location — show disclosure dialog only once
    final locationShown = prefs.getBool('location_dialog_shown') ?? false;
    LocationPermission geoPermission = await Geolocator.checkPermission();

    if (!locationShown) {
      await _showLocationDisclosureDialog();
      await prefs.setBool('location_dialog_shown', true);
    }

    if (geoPermission == LocationPermission.denied) {
      geoPermission = await Geolocator.requestPermission();
    }

    if (Platform.isIOS) {
      if (geoPermission == LocationPermission.whileInUse) {
        final alwaysStatus = await Permission.locationAlways.request();
        debugPrint('iOS locationAlways status: $alwaysStatus');
      }
    } else {
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }
    }

    final finalPermission = await Geolocator.checkPermission();
    debugPrint('Final location permission: $finalPermission');
  }

  Future<void> _showNotificationDisclosureDialog() async {
    if (Get.context == null) return;
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF7C8D3C)),
            SizedBox(width: 8),
            Text('Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mayfair Driver needs notifications to:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: 10),
            _DisclosureItem(
              icon: Icons.trip_origin,
              text: 'Alert you when a new trip is assigned or updated.',
            ),
            SizedBox(height: 6),
            _DisclosureItem(
              icon: Icons.my_location,
              text: 'Show a persistent status bar indicator while location tracking is active during a trip.',
            ),
            SizedBox(height: 6),
            _DisclosureItem(
              icon: Icons.info_outline,
              text: 'Notify you of important trip reminders and updates.',
            ),
            SizedBox(height: 14),
            Text(
              'You can manage notification preferences anytime in your device settings.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Not Now', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C8D3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Allow Notifications'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showLocationDisclosureDialog() async {
    if (Get.context == null) return;
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF7C8D3C)),
            SizedBox(width: 8),
            Text('Location Access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mayfair Driver collects your location data to:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: 10),
            _DisclosureItem(
              icon: Icons.navigation,
              text: 'Share your real-time position with dispatch during active trips only.',
            ),
            SizedBox(height: 6),
            _DisclosureItem(
              icon: Icons.wifi_tethering,
              text: 'Continue tracking in the background while a trip is in progress.',
            ),
            SizedBox(height: 6),
            _DisclosureItem(
              icon: Icons.route,
              text: 'Record trip routes for accurate fare calculation.',
            ),
            SizedBox(height: 14),
            Text(
              'Your location is only collected and shared during active trips and is never sold to third parties.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C8D3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    if (_activeTripId == null) {
      stop();
    }
    super.onClose();
  }
}

// ── Android background service entry point ────────────────────────────────────
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  String? authToken;
  int? tripId;
  Timer? timer;

  service.on('setToken').listen((event) {
    authToken = event!['token'];
  });

  service.on('setTripId').listen((event) {
    tripId = event!['tripId'];
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Mayfair Driver',
        content: tripId != null
            ? 'Trip active — sharing location'
            : 'Standby — location sharing paused',
      );
    }
  });

  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  timer = Timer.periodic(const Duration(seconds: 30), (_) async {
    if (authToken == null || authToken!.isEmpty) return;
    if (tripId == null) {
      debugPrint('Android LocationService: no active trip — skipping');
      return;
    }
    try {
      final position = await _getPosition();
      if (position != null) {
        await _sendLocationToApi(
          token: authToken!,
          latitude: position.latitude,
          longitude: position.longitude,
          tripId: tripId,
        );
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Mayfair Driver',
            content: 'Trip active — ${DateTime.now().toString().substring(11, 16)}',
          );
        }
      }
    } catch (e) {
      debugPrint('Android background location error: $e');
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

Future<Position?> _getPosition() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  } catch (e) {
    debugPrint('Get position error: $e');
    return null;
  }
}

Future<void> _sendLocationToApi({
  required String token,
  required double latitude,
  required double longitude,
  int? tripId,
}) async {
  try {
    final apiService = ApiService();
    await apiService.updateDriverLocation(
      token: token,
      latitude: latitude,
      longitude: longitude,
      tripId: tripId,
    );
  } catch (e) {
    debugPrint('Send location error: $e');
  }
}

class _DisclosureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DisclosureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7C8D3C)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
