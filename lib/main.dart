import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:limo_guy/controllers/login_controller.dart';
import 'package:limo_guy/services/location_update_service.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'core/app_theme.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  
  // Set preferred orientations (optional - portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize location service (single instance)
  final locationService = Get.put(LocationUpdateService(), permanent: true);
  await locationService.initialize();
  
  runApp(const MyApp());
}

/// Keeps location updating in foreground and background; stops only when app is killed (detached).
class _AppLifecycleWrapper extends StatefulWidget {
  const _AppLifecycleWrapper({required this.child});

  final Widget child;

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App back in foreground — ensure location is running if logged in
        _startLocationServiceIfLoggedIn();
        break;
      case AppLifecycleState.detached:
        // App is being killed / detached — stop location updates
        _stopLocationService();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // Keep location running in background — do not stop
        break;
    }
  }

  void _stopLocationService() {
    try {
      if (Get.isRegistered<LocationUpdateService>()) {
        Get.find<LocationUpdateService>().stop();
      }
    } catch (_) {}
  }

  void _startLocationServiceIfLoggedIn() {
    try {
      if (Get.isRegistered<LoginController>() &&
          Get.isRegistered<LocationUpdateService>() &&
          Get.find<LoginController>().isAuthenticated) {
        Get.find<LocationUpdateService>().start();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LimoGuy Driver',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      
      // Initialize core controllers before app starts
      initialBinding: InitialBinding(),
      
      // Routing configuration
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      
      // Transition configuration
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      
      // Error handling & responsive text
      builder: (context, child) {
        return _AppLifecycleWrapper(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
            child: child!,
          ),
        );
      },
      
      // Locale configuration (optional)
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}