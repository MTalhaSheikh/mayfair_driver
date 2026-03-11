import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:limo_guy/controllers/home_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../services/api_service.dart';
import '../services/location_update_service.dart';

enum TripProgressStage { onTheWay, arrived, pickPassenger, finishedTrip }

class TripInfoController extends GetxController {
  final ApiService _apiService = ApiService();

  // Trip data
  late final TripModel trip;

  final RxString currentTripId = ''.obs;
  final RxString pickupTitle = ''.obs;
  final RxString pickupSubtitle = ''.obs;
  final RxString dropoffTitle = ''.obs;
  final RxString dropoffSubtitle = ''.obs;
  final RxDouble pickupLat = 0.0.obs;
  final RxDouble pickupLng = 0.0.obs;
  final RxDouble dropoffLat = 0.0.obs;
  final RxDouble dropoffLng = 0.0.obs;
  final RxString scheduledLabel = ''.obs;
  final RxDouble distanceMiles = 0.0.obs;
  final RxInt durationMins = 0.obs;
  final RxString passengerName = ''.obs;
  final RxString passengerPhone = ''.obs;
  final RxString notes = ''.obs;

  // CRITICAL: Reactive stage that triggers UI updates
  final Rx<TripProgressStage> stage = TripProgressStage.onTheWay.obs;
  final RxBool isUpdatingStatus = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTripData();
  }

  /// Load trip data from arguments
  void _loadTripData() async {
    try {
      final args = Get.arguments;

      if (args != null && args is TripModel) {
        trip = args;

        // Update observables
        currentTripId.value = trip.id.toString();
        pickupTitle.value = trip.pickupTitle;
        pickupSubtitle.value = trip.pickupSubtitle;
        dropoffTitle.value = trip.dropoffTitle;
        dropoffSubtitle.value = trip.dropoffSubtitle;
        pickupLat.value = trip.pickupLat;
        pickupLng.value = trip.pickupLng;
        dropoffLat.value = trip.dropoffLat;
        dropoffLng.value = trip.dropoffLng;
        scheduledLabel.value = trip.scheduledLabel;
        distanceMiles.value = trip.distanceMiles;
        durationMins.value = trip.durationMins;
        passengerName.value = trip.displayPassengerName;
        notes.value = trip.displayNotes;
        passengerPhone.value = trip.customerPhone ?? 'Phone not available';

        // Load and set the initial stage
        await _setInitialStage();
        // If "On the way" was already pressed (saved or API status), send trip id with location
        if (await _isTripAlreadyStarted()) {
          await Get.find<LocationUpdateService>().setActiveTripId(trip.id);
        }
      } else {
        print('Warning: No trip data provided to TripInfoController');
        _setDefaultValues();
      }
    } catch (e) {
      print('Error loading trip data: $e');
      _setDefaultValues();
    }
  }

  Future<void> _setInitialStage() async {
    try {
      // Priority 1: Check locally saved status first (most recent)
      final savedStatus = await _getSavedTripStatus(trip.id);

      if (savedStatus != null && savedStatus.isNotEmpty) {
        final savedStage = _stageFromStatus(savedStatus);
        if (savedStage != null) {
          print('✅ Loading saved status: $savedStatus -> $savedStage');
          stage.value = savedStage;
          update(); // Force UI update
          return;
        }
      }

      // Priority 2: Use raw API status string
      if (trip.status.isNotEmpty) {
        final fromRaw = _stageFromStatus(trip.status);
        if (fromRaw != null) {
          print('✅ Using API status: ${trip.status} -> $fromRaw');
          stage.value = fromRaw;
          await _saveTripStatusLocally(trip.id, trip.status);
          update(); // Force UI update
          return;
        }
      }

      // Priority 3: Fallback to tripStatus enum
      TripProgressStage fallbackStage;
      String fallbackStatus;

      switch (trip.tripStatus) {
        case TripStatus.pending:
        case TripStatus.inProgress:
          fallbackStage = TripProgressStage.onTheWay;
          fallbackStatus = 'on_the_way';
          break;
        case TripStatus.completed:
          fallbackStage = TripProgressStage.finishedTrip;
          fallbackStatus = 'completed';
          break;
        case TripStatus.canceled:
          fallbackStage = TripProgressStage.onTheWay;
          fallbackStatus = 'on_the_way';
          break;
      }

      print('✅ Using fallback status: ${trip.tripStatus} -> $fallbackStage');
      stage.value = fallbackStage;
      await _saveTripStatusLocally(trip.id, fallbackStatus);
      update(); // Force UI update
    } catch (e) {
      print('❌ Error in _setInitialStage: $e');
      stage.value = TripProgressStage.onTheWay;
      update();
    }
  }

  /// True only if the driver has actually pressed "On the way". Do not use saved 'on_the_way' (we use that as fallback for pending).
  Future<bool> _isTripAlreadyStarted() async {
    if (stage.value == TripProgressStage.arrived ||
        stage.value == TripProgressStage.pickPassenger) {
      return true;
    }
    if (stage.value != TripProgressStage.onTheWay) return false;
    // API says they started
    if (_isStartedStatus(trip.status)) return true;
    // Saved status from a real tap (arrived/picked_up/completed), not fallback 'on_the_way'
    final savedStatus = await _getSavedTripStatus(trip.id);
    return _isSavedStatusAfterStart(savedStatus);
  }

  /// Saved status written after driver actually advanced (not the fallback 'on_the_way' for pending).
  static bool _isSavedStatusAfterStart(String? status) {
    if (status == null || status.isEmpty) return false;
    final t = status.toLowerCase().trim();
    return t == 'arrived' || t == 'picked_up' || t == 'pickedup' || t == 'completed';
  }

  static bool _isStartedStatus(String status) {
    switch (status) {
      case 'on_the_way':
      case 'ontheway':
      case 'arrived':
      case 'picked_up':
      case 'pickedup':
        return true;
      default:
        return false;
    }
  }

  void _setDefaultValues() {
    currentTripId.value = '';
    pickupTitle.value = 'Pickup location';
    pickupSubtitle.value = '';
    dropoffTitle.value = 'Dropoff location';
    dropoffSubtitle.value = '';
    scheduledLabel.value = 'No trip data';
    distanceMiles.value = 0.0;
    durationMins.value = 0;
    passengerName.value = 'Passenger';
    passengerPhone.value = '+1 (XXX) XXX-XXXX';
    notes.value = '';
  }

  String get stageTitle {
    switch (stage.value) {
      case TripProgressStage.onTheWay:
        return 'On The Way';
      case TripProgressStage.arrived:
        return 'Arrived';
      case TripProgressStage.pickPassenger:
        return 'Pick Passenger';
      case TripProgressStage.finishedTrip:
        return 'Finished Trip';
    }
  }
/// Map API status string to local stage
TripProgressStage? _stageFromStatus(String status) {
  switch (status.toLowerCase().trim()) {
    case 'on_the_way':
    case 'ontheway':
      return TripProgressStage.onTheWay;
    case 'arrived':
      return TripProgressStage.arrived;
    case 'picked_up':
    case 'pickedup':
      return TripProgressStage.pickPassenger;
    case 'finished_trip_pending': // NEW: local-only status
      return TripProgressStage.finishedTrip;
    case 'completed':
    case 'finished':
      return TripProgressStage.finishedTrip;
    default:
      print('⚠️ Unknown status: $status');
      return null;
  }
}

  /// Get API status string for current stage
  String _getApiStatusForStage(TripProgressStage stageValue) {
    switch (stageValue) {
      case TripProgressStage.onTheWay:
        return 'on_the_way';
      case TripProgressStage.arrived:
        return 'arrived';
      case TripProgressStage.pickPassenger:
        return 'picked_up';
      case TripProgressStage.finishedTrip:
        return 'completed';
    }
  }

  /// Get auth token from SharedPreferences
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  /// Save trip status locally - CRITICAL for persistence
  Future<void> _saveTripStatusLocally(int tripId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'trip_status_$tripId';
      await prefs.setString(key, status);
      print('💾 Saved locally: $key = $status');
    } catch (e) {
      print('❌ Error saving trip status locally: $e');
    }
  }

  /// Get saved trip status from local storage
  Future<String?> _getSavedTripStatus(int tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'trip_status_$tripId';
      final status = prefs.getString(key);
      if (status != null) {
        print('📂 Retrieved locally: $key = $status');
      }
      return status;
    } catch (e) {
      print('❌ Error getting saved trip status: $e');
      return null;
    }
  }

  /// Clear saved trip status
  Future<void> _clearTripStatus(int tripId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'trip_status_$tripId';
      await prefs.remove(key);
      print('🗑️ Cleared: $key');
    } catch (e) {
      print('❌ Error clearing trip status: $e');
    }
  }

  /// Update trip status via API
  Future<bool> _updateTripStatusApi(String status) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        Get.snackbar(
          'Error',
          'Authentication token not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      print('🔄 Updating trip ${trip.id} to status: $status');

      double? latitude;
      double? longitude;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (e) {
        print('Could not get position for status update: $e');
      }

      final success = await _apiService.updateTripStatus(
        token: token,
        tripId: trip.id,
        status: status,
        latitude: latitude,
        longitude: longitude,
      );

      return success;
    } on ApiException catch (e) {
      print('❌ API Exception: ${e.message}');
      final message = e.statusCode == 0
          ? 'Network error. Please check your connection and try again.'
          : (e.message.isNotEmpty
                ? e.message
                : 'Failed to update trip status. Please try again.');
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    } catch (e) {
      print('❌ Unexpected error: $e');
      Get.snackbar(
        'Error',
        'Unexpected error. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  /// Advance to next stage - MAIN ACTION
  void advanceStage() async {
    // Prevent multiple simultaneous updates
    if (isUpdatingStatus.value) {
      print('⚠️ Update already in progress, ignoring...');
      return;
    }

    isUpdatingStatus.value = true;
    print('⏩ Advancing from stage: ${stage.value}');

    try {
      switch (stage.value) {
        case TripProgressStage.onTheWay:
          // Stage 1 → 2: On the way → Arrived (driver taps "On the way" to start the trip)
          final newStatus = _getApiStatusForStage(TripProgressStage.onTheWay);
          final success = await _updateTripStatusApi(newStatus);

          if (success) {
            // Pass trip id with location API once driver has started the trip
            await Get.find<LocationUpdateService>().setActiveTripId(trip.id);
            stage.value = TripProgressStage.arrived;
            update();
            print("stage: ${stage.value}");
            await _saveTripStatusLocally(trip.id, "arrived");
            Get.snackbar(
              'Status Updated',
              'You are on the way to pickup location',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          }
          break;

        case TripProgressStage.arrived:
          // Stage 2 → 3: Arrived → Pick Passenger
          final newStatus = _getApiStatusForStage(
            TripProgressStage.arrived,
          );
          final success = await _updateTripStatusApi(newStatus);

          if (success) {
            stage.value = TripProgressStage.pickPassenger;
            update();
            print("stage: ${stage.value}");
            await _saveTripStatusLocally(trip.id, "picked_up");
            Get.snackbar(
              'Status Updated',
              'You have arrived at pickup location',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          }
          break;

        case TripProgressStage.pickPassenger:
          // Stage 2 → 3: Arrived → Pick Passenger
          final newStatus = _getApiStatusForStage(
            TripProgressStage.pickPassenger,
          );
          final success = await _updateTripStatusApi(newStatus);

          if (success) {
            stage.value = TripProgressStage.finishedTrip;
            update();
            print("stage: ${stage.value}");
            await _saveTripStatusLocally(trip.id, "completed");
            Get.snackbar(
              'Status Updated',
              'Passenger picked up',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          }
          break;

        case TripProgressStage.finishedTrip:
          final HomeController homeController = Get.find<HomeController>();
          // Stage 4: Actually complete the trip via API
          final newStatus = _getApiStatusForStage(
            TripProgressStage.finishedTrip,
          );
          final success = await _updateTripStatusApi(newStatus);
           Get.back();
          if (success) {
            homeController.refreshTrips();
            Get.snackbar(
              'Trip Completed',
              'Trip has been marked as completed',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );

            // Clear local storage when trip is completed
            await _clearTripStatus(trip.id);
          }
          break;
      }
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  @override
  void onClose() {
    // Clear trip ID when trip ends / leaving trip screen
    Get.find<LocationUpdateService>().setActiveTripId(null);
    super.onClose();
  }
}
