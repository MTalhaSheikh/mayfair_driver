import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/login_controller.dart';
import 'api_service.dart';

/// Sends driver location to the API every 10 seconds, even in background.
class LocationUpdateService extends GetxService {
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();

  int? _activeTripId;

  /// Initialize the background service
  Future<void> initialize() async {
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'driver_location_channel',
        initialNotificationTitle: 'Limo Guy',
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

  /// Set the active trip id
  Future<void> setActiveTripId(int? tripId) async {
    _activeTripId = tripId;
    if (await _backgroundService.isRunning()) {
      _backgroundService.invoke('setTripId', {'tripId': tripId});
    }
  }

  /// Start the background location service
  Future<void> start() async {
    final token = Get.find<LoginController>().authToken.value;
    if (token.isEmpty) return;

    // Request permissions
    await _requestPermissions();

    // Start the background service
    await _backgroundService.startService();

    // Send initial data
    _backgroundService.invoke('setToken', {'token': token});
    if (_activeTripId != null) {
      _backgroundService.invoke('setTripId', {'tripId': _activeTripId});
    }
  }

  /// Stop the background location service
  Future<void> stop() async {
    _backgroundService.invoke('stopService');
    _activeTripId = null;
  }

  Future<void> _requestPermissions() async {
    // Show notification disclosure then request permission (Android 13+)
    if (await Permission.notification.isDenied) {
      await _showNotificationDisclosureDialog();
      await Permission.notification.request();
    }

    // Show location disclosure then request permission
    final locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      await _showLocationDisclosureDialog();
    }

    await Permission.location.request();
    await Permission.locationAlways.request();
  }

  /// Show a disclosure dialog explaining why notification access is needed
  Future<void> _showNotificationDisclosureDialog() async {
    if (Get.context == null) return;

    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF7C8D3C)),
            SizedBox(width: 8),
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Limo Guy needs notifications to:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(height: 10),
            _DisclosureItem(
              icon: Icons.trip_origin,
              text: 'Alert you when a new trip is assigned or updated.',
            ),
            SizedBox(height: 6),
            _DisclosureItem(
              icon: Icons.my_location,
              text: 'Show a persistent status bar indicator while location tracking is active in the background.',
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
            child: const Text(
              'Not Now',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C8D3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Allow Notifications'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Show a disclosure dialog explaining why location access is needed
  Future<void> _showLocationDisclosureDialog() async {
    if (Get.context == null) return;

    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF7C8D3C)),
            SizedBox(width: 8),
            Text(
              'Location Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Limo Guy collects your location data to:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(height: 10),
            _DisclosureItem(
              icon: Icons.navigation,
              text: 'Share your real-time position with passengers during active trips.',
            ),
            SizedBox(height: 6),
            _DisclosureItem(
              icon: Icons.wifi_tethering,
              text: 'Continue tracking in the background even when the app is closed.',
            ),
            SizedBox(height: 6),
            _DisclosureItem(
              icon: Icons.route,
              text: 'Record trip routes for accurate fare calculation.',
            ),
            SizedBox(height: 14),
            Text(
              'Your location is only shared during active trips and is never sold to third parties.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Not Now',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C8D3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Allow Location'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}

/// Background service entry point
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
  });

  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  // Send location every 30 seconds
  timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (authToken == null || authToken!.isEmpty) return;

    try {
      final position = await _getPosition();
      if (position != null) {
        await _sendLocationToApi(
          token: authToken!,
          latitude: position.latitude,
          longitude: position.longitude,
          tripId: tripId,
        );

        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Limo Guy',
            content:
                'Last update: ${DateTime.now().toString().substring(11, 19)}',
          );
        }
      }
    } catch (e) {
      print('Background location error: $e');
    }
  });

  // Send first location immediately
  if (authToken != null) {
    final position = await _getPosition();
    if (position != null) {
      await _sendLocationToApi(
        token: authToken!,
        latitude: position.latitude,
        longitude: position.longitude,
        tripId: tripId,
      );

      // Set initial notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Limo Guy',
          content: 'Location tracking started',
        );
      }
    }
  }
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
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  } catch (e) {
    print('Get position error: $e');
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
    print('Send location error: $e');
  }
}

/// Small row widget used inside disclosure dialogs.
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
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
