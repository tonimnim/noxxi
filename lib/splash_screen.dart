import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/core/widgets/app_logo.dart';
import 'package:noxxi/core/widgets/auth_wrapper.dart';
import 'package:noxxi/core/providers/auth_state_provider.dart';
import 'package:noxxi/features/home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations
    _animationController.forward();
    
    // Run background processes and navigate after 3 seconds
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Run necessary background processes
    await Future.wait([
      _checkConnectivity(),
      _loadUserPreferences(),
      _initializeServices(),
      // Ensure minimum 3 seconds splash screen
      Future.delayed(const Duration(seconds: 3)),
    ]);
    
    if (!mounted) return;
    
    // Navigate to auth wrapper which will handle auth state
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthWrapper(
          authenticatedWidget: HomeScreen(),
        ),
      ),
    );
  }

  Future<void> _checkConnectivity() async {
    // Check internet connectivity
    // TODO: Implement actual connectivity check
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _loadUserPreferences() async {
    // Load user preferences from local storage
    // TODO: Implement SharedPreferences loading
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _initializeServices() async {
    // Initialize any other required services
    // TODO: Initialize push notifications, analytics, etc.
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppColors.primaryBackground.withOpacity(0.8),
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLogo(
                        fontSize: 72,
                        color: AppColors.primaryText,
                      ),
                      const SizedBox(height: 80),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryText.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}