import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mayfair_driver/controllers/login_controller.dart';
import 'package:mayfair_driver/routes/app_routes.dart';
/// Middleware to check if user is authenticated before accessing protected routes
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Check if LoginController exists and user is authenticated
    if (Get.isRegistered<LoginController>()) {
      final loginController = Get.find<LoginController>();
      
      // If not authenticated and trying to access protected route
      if (!loginController.isAuthenticated) {
        // Redirect to login
        return const RouteSettings(name: AppRoutes.login);
      }
    } else {
      // LoginController not found, redirect to login
      return const RouteSettings(name: AppRoutes.login);
    }
    
    // User is authenticated, allow access
    return null;
  }
}

/// Middleware to prevent authenticated users from accessing login screen
class LoginMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Check if user is already logged in
    if (Get.isRegistered<LoginController>()) {
      final loginController = Get.find<LoginController>();
      
      // If already authenticated, redirect to home
      if (loginController.isAuthenticated) {
        return const RouteSettings(name: AppRoutes.home);
      }
    }
    
    // User not authenticated, show login
    return null;
  }
}