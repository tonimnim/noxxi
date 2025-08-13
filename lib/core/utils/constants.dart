class AppConstants {
  // App Information
  static const String appName = 'Noxxi';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Event Ticketing Platform for Africa';
  
  // API Configuration
  static const int apiTimeout = 30000; // 30 seconds
  static const int uploadTimeout = 120000; // 2 minutes
  static const int maxRetries = 3;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Duration
  static const Duration cacheValidDuration = Duration(hours: 1);
  static const Duration imageCacheDuration = Duration(days: 7);
  
  // File Size Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Supported Image Formats
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  
  // Supported Currencies
  static const Map<String, String> supportedCurrencies = {
    'KES': 'Kenyan Shilling',
    'NGN': 'Nigerian Naira',
    'ZAR': 'South African Rand',
    'GHS': 'Ghanaian Cedi',
    'UGX': 'Ugandan Shilling',
    'TZS': 'Tanzanian Shilling',
    'EGP': 'Egyptian Pound',
    'USD': 'US Dollar',
  };
  
  // Default Currency
  static const String defaultCurrency = 'KES';
  
  // Countries
  static const Map<String, String> africanCountries = {
    'KE': 'Kenya',
    'NG': 'Nigeria',
    'ZA': 'South Africa',
    'GH': 'Ghana',
    'UG': 'Uganda',
    'TZ': 'Tanzania',
    'EG': 'Egypt',
    'ET': 'Ethiopia',
    'RW': 'Rwanda',
    'SN': 'Senegal',
  };
  
  // Event Categories
  static const Map<String, String> eventCategories = {
    'music': 'Music & Concerts',
    'sports': 'Sports',
    'arts': 'Arts & Theater',
    'business': 'Business & Professional',
    'food': 'Food & Drink',
    'charity': 'Charity & Causes',
    'education': 'Education',
    'fashion': 'Fashion',
    'film': 'Film & Media',
    'health': 'Health & Wellness',
    'hobbies': 'Hobbies',
    'holiday': 'Holiday',
    'home': 'Home & Lifestyle',
    'auto': 'Auto, Boat & Air',
    'other': 'Other',
  };
  
  // Ticket Types
  static const Map<String, String> ticketTypes = {
    'regular': 'Regular',
    'vip': 'VIP',
    'vvip': 'VVIP',
    'early_bird': 'Early Bird',
    'group': 'Group',
    'student': 'Student',
    'couple': 'Couple',
    'family': 'Family',
  };
  
  // Payment Methods
  static const Map<String, String> paymentMethods = {
    'mpesa': 'M-Pesa',
    'paystack': 'Card Payment',
    'cash': 'Cash at Venue',
  };
  
  // Order Status
  static const Map<String, String> orderStatus = {
    'pending': 'Pending Payment',
    'processing': 'Processing',
    'completed': 'Completed',
    'failed': 'Failed',
    'cancelled': 'Cancelled',
    'refunded': 'Refunded',
  };
  
  // Ticket Status
  static const Map<String, String> ticketStatus = {
    'valid': 'Valid',
    'used': 'Used',
    'cancelled': 'Cancelled',
    'expired': 'Expired',
    'transferred': 'Transferred',
  };
  
  // Date Time Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';
  static const String eventDateFormat = 'EEE, dd MMM yyyy';
  static const String eventTimeFormat = 'h:mm a';
  
  // Regular Expressions
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp phoneRegex = RegExp(
    r'^(\+?254|0)?[17]\d{8}$',
  );
  
  static final RegExp urlRegex = RegExp(
    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
  );
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Border Radius
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
  
  // Spacing
  static const double tinySpacing = 4.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  
  // Icon Sizes
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;
  
  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection';
  static const String serverErrorMessage = 'Something went wrong. Please try again';
  static const String sessionExpiredMessage = 'Your session has expired. Please login again';
  static const String unauthorizedMessage = 'You are not authorized to perform this action';
  
  // Success Messages
  static const String loginSuccessMessage = 'Welcome back!';
  static const String registerSuccessMessage = 'Account created successfully!';
  static const String profileUpdateSuccessMessage = 'Profile updated successfully';
  static const String passwordChangeSuccessMessage = 'Password changed successfully';
  static const String bookingSuccessMessage = 'Booking confirmed successfully!';
  
  // Storage Keys
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String currencyKey = 'app_currency';
  static const String countryKey = 'app_country';
  static const String onboardingKey = 'onboarding_completed';
  static const String notificationKey = 'notifications_enabled';
}