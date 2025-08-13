import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6B46C1);  // Purple
  static const Color primaryLight = Color(0xFF9F7AEA);
  static const Color primaryDark = Color(0xFF553C9A);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFED8936);  // Orange
  static const Color secondaryLight = Color(0xFFF6AD55);
  static const Color secondaryDark = Color(0xFFDD6B20);
  
  // Accent Colors
  static const Color accent = Color(0xFF38B2AC);  // Teal
  static const Color accentLight = Color(0xFF4FD1C5);
  static const Color accentDark = Color(0xFF319795);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x33000000);
  
  // Category Colors (for event categories)
  static const Map<String, Color> categoryColors = {
    'music': Color(0xFF8B5CF6),
    'sports': Color(0xFF10B981),
    'arts': Color(0xFFF59E0B),
    'business': Color(0xFF3B82F6),
    'food': Color(0xFFEF4444),
    'charity': Color(0xFFEC4899),
    'education': Color(0xFF14B8A6),
    'fashion': Color(0xFFF97316),
    'film': Color(0xFF6366F1),
    'health': Color(0xFF84CC16),
    'hobbies': Color(0xFFA855F7),
    'holiday': Color(0xFF06B6D4),
    'home': Color(0xFF78716C),
    'auto': Color(0xFF0EA5E9),
    'other': Color(0xFF6B7280),
  };
  
  // Currency Colors (for different payment methods)
  static const Map<String, Color> currencyColors = {
    'KES': Color(0xFF10B981),  // M-Pesa green
    'NGN': Color(0xFF059669),
    'ZAR': Color(0xFFFBBF24),
    'GHS': Color(0xFFEF4444),
    'UGX': Color(0xFFDC2626),
    'TZS': Color(0xFF3B82F6),
    'EGP': Color(0xFF1E40AF),
    'USD': Color(0xFF059669),
  };
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondaryDark],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successLight, successDark],
  );
  
  // Material Color Swatches
  static MaterialColor primarySwatch = MaterialColor(
    primary.value,
    const <int, Color>{
      50: Color(0xFFF5F3FF),
      100: Color(0xFFEDE9FE),
      200: Color(0xFFDDD6FE),
      300: Color(0xFFC4B5FD),
      400: Color(0xFFA78BFA),
      500: primary,
      600: Color(0xFF7C3AED),
      700: primaryDark,
      800: Color(0xFF5B21B6),
      900: Color(0xFF4C1D95),
    },
  );
  
  // Ticket Status Colors
  static const Map<String, Color> ticketStatusColors = {
    'valid': success,
    'used': gray500,
    'cancelled': error,
    'expired': warning,
    'transferred': info,
  };
  
  // Order Status Colors
  static const Map<String, Color> orderStatusColors = {
    'pending': warning,
    'processing': info,
    'completed': success,
    'failed': error,
    'cancelled': gray500,
    'refunded': secondary,
  };
}