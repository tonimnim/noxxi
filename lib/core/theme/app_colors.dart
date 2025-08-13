import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // Frosted Glass Theme - Confirmed Design System
  static const Color frostedBackground = Color(0xFFD8D8D8); // Base grey background #d8d8d8
  static const Color frostedGlass = Color(0xFFF0F0F0); // Glass overlay color (240,240,240)
  static const double frostedOpacity = 0.3; // Glass opacity
  static const double frostedBorderOpacity = 0.4; // Border opacity  
  static const double frostedBlur = 30.0; // Default blur amount
  static const double liquidBlur = 40.0; // Stronger blur for liquid effect
  
  // Glass Container Gradient Colors - For Liquid Effect
  static Color glassGradientStart = Colors.white.withOpacity(0.15);
  static Color glassGradientMiddle = const Color(0xFFF0F0F0).withOpacity(0.08);
  static Color glassGradientEnd = Colors.white.withOpacity(0.12);
  static Color glassBorder = Colors.white.withOpacity(0.25);
  
  // Primary backgrounds
  static const Color primaryBackground = Color(0xFFFFFFFF); // White
  static const Color scaffoldBackground = frostedBackground; // Use frosted background
  static const Color pureBlack = Color(0xFF000000); // Pure black

  // Text colors - Black only
  static const Color darkText = Color(0xFF000000); // Black
  static const Color primaryText = darkText; // Black
  static const Color secondaryText = Color(0xFF666666); // Gray (between black and white)
  static const Color disabledText = Color(0xFF999999); // Light gray

  // Card and surface colors
  static const Color cardBackground = Color(0xFFFFFFFF); // White
  static const Color surfaceLight = Color(0xFFFFFFFF); // White

  // Accent - Using black
  static const Color primaryAccent = Color(0xFF000000); // Black
  static const Color accentLight = Color(0xFF666666); // Gray
  static const Color accentDark = Color(0xFF000000); // Black

  // Functional colors - Using shades of gray
  static const Color success = Color(0xFF000000); // Black
  static const Color error = Color(0xFF000000); // Black
  static const Color warning = Color(0xFF666666); // Gray
  static const Color info = Color(0xFF000000); // Black

  // Border and divider colors
  static const Color border = Color(0xFFE0E0E0); // Light gray
  static const Color divider = Color(0xFFE0E0E0); // Light gray

  // Input field colors
  static const Color inputBackground = Color(0xFFF5F5F5); // Very light gray
  static const Color inputBorder = Color(0xFFE0E0E0); // Light gray
  static const Color inputFocusedBorder = Color(0xFF000000); // Black

  // Button colors
  static const Color buttonPrimary = Color(0xFF000000); // Black
  static const Color buttonSecondary = Color(0xFFF0F0F0); // Light gray
  static const Color buttonDisabled = Color(0xFFE0E0E0); // Light gray
}

// Frosted Glass Widget Helper
class FrostedGlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const FrostedGlassBox({
    Key? key,
    required this.child,
    this.borderRadius = 22.0,
    this.blur = 30.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.frostedGlass.withOpacity(AppColors.frostedOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(AppColors.frostedBorderOpacity),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}