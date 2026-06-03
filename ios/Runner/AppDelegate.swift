import Flutter
import UIKit
import CoreLocation
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {

  private var locationManager: CLLocationManager?
  private var flutterEngine: FlutterEngine?
  private var flutterChannel: FlutterMethodChannel?
  private var lastSentTime: Date = Date.distantPast

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAODIKaO69Wj8CpRb6vkAio-aqBFsxfFsQ")
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Called after Flutter engine is ready — safest place to setup channels
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    setupChannelIfNeeded()
  }

  private func setupChannelIfNeeded() {
    guard flutterChannel == nil else { return }

    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("❌ [MayFair] FlutterViewController not found")
      return
    }

    flutterChannel = FlutterMethodChannel(
      name: "com.mayfair.location",
      binaryMessenger: controller.binaryMessenger
    )

    flutterChannel?.setMethodCallHandler { [weak self] call, result in
      print("📲 [MayFair] Flutter called: \(call.method)")
      switch call.method {
      case "startBackgroundLocation":
        self?.startNativeLocationUpdates()
        result(true)
      case "stopBackgroundLocation":
        self?.stopNativeLocationUpdates()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    print("✅ [MayFair] Flutter channel setup complete")
  }

  // MARK: - Native CLLocationManager

  func startNativeLocationUpdates() {
    print("🚀 [MayFair] startNativeLocationUpdates called")

    if locationManager == nil {
      locationManager = CLLocationManager()
      locationManager?.delegate = self
    }

    locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    locationManager?.distanceFilter  = kCLDistanceFilterNone
    locationManager?.allowsBackgroundLocationUpdates    = true
    locationManager?.pausesLocationUpdatesAutomatically = false
    locationManager?.showsBackgroundLocationIndicator   = true

    // Check current auth and request if needed
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = locationManager!.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }

    print("📍 [MayFair] Auth status: \(status.rawValue)")

    switch status {
    case .notDetermined:
      locationManager?.requestAlwaysAuthorization()
    case .authorizedWhenInUse:
      locationManager?.requestAlwaysAuthorization()
      locationManager?.startUpdatingLocation()
    case .authorizedAlways:
      locationManager?.startUpdatingLocation()
    case .denied, .restricted:
      print("❌ [MayFair] Location denied — cannot start")
    @unknown default:
      locationManager?.startUpdatingLocation()
    }
  }

  func stopNativeLocationUpdates() {
    locationManager?.stopUpdatingLocation()
    print("🛑 [MayFair] Native location stopped")
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager,
                       didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }

    print("📍 [MayFair] Got location: \(location.coordinate.latitude), \(location.coordinate.longitude) accuracy: \(location.horizontalAccuracy)m")

    // Throttle to 25 seconds
    let now = Date()
    guard now.timeIntervalSince(lastSentTime) >= 25 else {
      print("⏱ [MayFair] Throttled — skipping")
      return
    }
    lastSentTime = now

    let data: [String: Any] = [
      "latitude":  location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "accuracy":  location.horizontalAccuracy,
      "timestamp": location.timestamp.timeIntervalSince1970
    ]

    // Push to Flutter
    DispatchQueue.main.async { [weak self] in
      if self?.flutterChannel == nil {
        print("⚠️ [MayFair] Channel nil — calling setupChannelIfNeeded")
        self?.setupChannelIfNeeded()
      }
      self?.flutterChannel?.invokeMethod("onLocationUpdate", arguments: data)
      print("📤 [MayFair] Sent to Flutter channel")
    }
  }

  func locationManager(_ manager: CLLocationManager,
                       didFailWithError error: Error) {
    print("❌ [MayFair] Location error: \(error.localizedDescription)")
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if #available(iOS 14.0, *) {
      print("🔐 [MayFair] Auth changed: \(manager.authorizationStatus.rawValue)")
      switch manager.authorizationStatus {
      case .authorizedAlways, .authorizedWhenInUse:
        manager.startUpdatingLocation()
      case .denied, .restricted:
        stopNativeLocationUpdates()
      default:
        break
      }
    }
  }

  func locationManager(_ manager: CLLocationManager,
                       didChangeAuthorization status: CLAuthorizationStatus) {
    print("🔐 [MayFair] Auth changed (legacy): \(status.rawValue)")
    if status == .authorizedAlways || status == .authorizedWhenInUse {
      manager.startUpdatingLocation()
    }
  }
}