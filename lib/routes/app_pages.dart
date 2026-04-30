import 'package:get/get.dart';
import 'package:mayfair_driver/views/login/auth_middleware.dart';
import '../routes/app_routes.dart';
import '../bindings/detail_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/login_binding.dart';
import '../bindings/map_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/trip_info_binding.dart';
import '../views/detail_view.dart';
import '../views/home_view.dart';
import '../views/login/login_view.dart';
import '../views/profile_view.dart';
import '../views/splash_view.dart';
import '../views/trip_info_view.dart';

class AppPages {
  // Prevent instantiation
  AppPages._();
  
  static const String initial = AppRoutes.splash;

  static final List<GetPage> routes = [
    // ========== PUBLIC ROUTES (No Authentication Required) ==========
    
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
      middlewares: [LoginMiddleware()], // Prevents access if already logged in
    ),
    
    // ========== PROTECTED ROUTES (Authentication Required) ==========
    
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()], // Requires authentication
    ),
    
    GetPage(
      name: AppRoutes.tripInfo,
      page: () => const TripInfoView(),
      binding: TripInfoBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    
    // GetPage(
    //   name: AppRoutes.map,
    //   page: () => const MapView(),
    //   binding: MapBinding(),
    //   transition: Transition.downToUp,
    //   fullscreenDialog: true,
    //   middlewares: [AuthMiddleware()],
    // ),
    
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    
    GetPage(
      name: AppRoutes.detail,
      page: () => const DetailView(),
      binding: DetailBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
  ];
  
  // ========== NAVIGATION HELPERS ==========
  
  /// Navigate to login and clear all previous routes
  static void toLogin() {
    Get.offAllNamed(AppRoutes.login);
  }
  
  /// Navigate to home and clear all previous routes
  static void toHome() {
    Get.offAllNamed(AppRoutes.home);
  }
  
  /// Navigate to profile
  static void toProfile() {
    Get.toNamed(AppRoutes.profile);
  }
  
  /// Navigate to map with optional trip data
  static void toMap({Map<String, dynamic>? arguments}) {
    Get.toNamed(AppRoutes.map, arguments: arguments);
  }
  
  /// Navigate to trip info with trip ID
  static void toTripInfo({required String tripId}) {
    Get.toNamed(AppRoutes.tripInfo, arguments: {'tripId': tripId});
  }
  
  /// Navigate to detail view
  static void toDetail({Map<String, dynamic>? arguments}) {
    Get.toNamed(AppRoutes.detail, arguments: arguments);
  }
  
  /// Go back to previous screen (with safety check)
  static void back() {
    if (Get.currentRoute != AppRoutes.home && Get.currentRoute != AppRoutes.login) {
      Get.back();
    }
  }
  
  /// Check if currently on a specific route
  static bool isCurrentRoute(String route) {
    return Get.currentRoute == route;
  }
}