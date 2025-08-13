import 'package:flutter/material.dart';
import '../../features/auth/models/user.dart';

class AppRouter {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  
  // Main navigation
  static const String home = '/home';
  static const String search = '/search';
  static const String tickets = '/tickets';
  static const String profile = '/profile';
  static const String scanner = '/scanner';
  
  // Event routes
  static const String eventDetails = '/event/:id';
  static const String eventCategory = '/category/:id';
  static const String createEvent = '/create-event';
  
  // Booking routes
  static const String checkout = '/checkout';
  static const String paymentSuccess = '/payment-success';
  static const String bookingDetails = '/booking/:id';
  
  // Profile routes
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String support = '/support';
  
  // Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => Container(), // Replace with SplashScreen
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => Container(), // Replace with LoginScreen
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => Container(), // Replace with RegisterScreen
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => Container(), // Replace with HomeScreen
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
  
  // Check if route requires authentication
  static bool requiresAuth(String? routeName) {
    const publicRoutes = [
      splash,
      login,
      register,
      forgotPassword,
    ];
    return !publicRoutes.contains(routeName);
  }
  
  // Check if route is for organizers only
  static bool requiresOrganizerRole(String? routeName) {
    const organizerRoutes = [
      createEvent,
      scanner,
    ];
    return organizerRoutes.contains(routeName);
  }
  
  // Navigate based on user role
  static String getHomeRoute(UserRole role) {
    switch (role) {
      case UserRole.organizer:
        return home;
      case UserRole.manager:
        return scanner;
      default:
        return home;
    }
  }
}