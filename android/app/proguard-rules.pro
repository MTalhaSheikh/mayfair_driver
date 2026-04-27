# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Google Maps
-keep class com.google.maps.** { *; }
-keep class com.google.android.gms.maps.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Flutter background service
-keep class id.flutter.flutter_background_service.** { *; }

# Keep all Flutter plugin registrars
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }