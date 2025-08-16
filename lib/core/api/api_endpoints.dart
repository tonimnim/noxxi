class ApiEndpoints {
  // Base URL - Update this with your Laravel server URL
  static const String baseUrl = 'http://localhost:8000'; // Change in production
  static const String apiPrefix = '/api';
  static const String baseApiUrl = '$baseUrl$apiPrefix';

  // Authentication Endpoints
  static const String register = '/auth/register';
  static const String registerOrganizer = '/auth/register-organizer';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String currentUser = '/user'; // Updated from /auth/me
  static const String refreshToken = '/auth/refresh'; // Kept for compatibility but not used
  static const String requestPasswordReset = '/auth/forgot-password'; // Updated endpoint
  static const String resetPassword = '/auth/reset-password'; // Updated endpoint
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  
  // User Profile Endpoints
  static const String updateProfile = '/profile/update';
  static const String uploadAvatar = '/profile/avatar';
  static const String changePassword = '/profile/change-password';
  static const String deleteAccount = '/profile/delete';
  
  // Events Endpoints
  static const String events = '/events';
  static const String eventDetails = '/events/{id}';
  static const String eventCategories = '/events/categories';
  static const String searchEvents = '/events/search';
  static const String featuredEvents = '/events/featured';
  static const String upcomingEvents = '/events/upcoming';
  static const String eventsNearby = '/events/nearby';
  
  // Organizer Events Endpoints
  static const String organizerEvents = '/organizer/events';
  static const String createEvent = '/organizer/events/create';
  static const String updateEvent = '/organizer/events/{id}/update';
  static const String deleteEvent = '/organizer/events/{id}/delete';
  static const String eventAnalytics = '/organizer/events/{id}/analytics';
  static const String eventAttendees = '/organizer/events/{id}/attendees';
  
  // Bookings & Tickets Endpoints
  static const String bookings = '/bookings';
  static const String createBooking = '/bookings/create';
  static const String bookingDetails = '/bookings/{id}';
  static const String cancelBooking = '/bookings/{id}/cancel';
  static const String myTickets = '/tickets';
  static const String ticketDetails = '/tickets/{id}';
  static const String transferTicket = '/tickets/{id}/transfer';
  static const String downloadTicket = '/tickets/{id}/download';
  
  // Payment Endpoints
  static const String initializePaystack = '/payments/paystack/initialize';
  static const String verifyPaystack = '/payments/paystack/verify';
  static const String initializeMpesa = '/payments/mpesa/initialize';
  static const String mpesaCallback = '/payments/mpesa/callback';
  static const String paymentHistory = '/payments/history';
  static const String paymentDetails = '/payments/{id}';
  static const String requestRefund = '/payments/{id}/refund';
  
  // Scanner Endpoints (Organizer)
  static const String validateTicket = '/scanner/validate';
  static const String checkinTicket = '/scanner/checkin';
  static const String scannerStats = '/scanner/stats/{eventId}';
  static const String downloadManifest = '/scanner/manifest/{eventId}';
  
  // Notifications Endpoints
  static const String notifications = '/notifications';
  static const String markAsRead = '/notifications/{id}/read';
  static const String markAllAsRead = '/notifications/read-all';
  static const String deleteNotification = '/notifications/{id}/delete';
  static const String notificationSettings = '/notifications/settings';
  
  // Search & Filter Endpoints
  static const String searchAll = '/search';
  static const String searchSuggestions = '/search/suggestions';
  static const String popularSearches = '/search/popular';
  
  // Support Endpoints
  static const String createSupportTicket = '/support/tickets/create';
  static const String supportTickets = '/support/tickets';
  static const String supportTicketDetails = '/support/tickets/{id}';
  static const String supportCategories = '/support/categories';
  static const String faqs = '/support/faqs';
  
  // Analytics Endpoints (Organizer)
  static const String dashboardStats = '/analytics/dashboard';
  static const String salesReport = '/analytics/sales';
  static const String attendanceReport = '/analytics/attendance';
  static const String revenueReport = '/analytics/revenue';
  
  // Settings Endpoints
  static const String appSettings = '/settings/app';
  static const String currencies = '/settings/currencies';
  static const String countries = '/settings/countries';
  static const String paymentMethods = '/settings/payment-methods';
  
  // Helper method to replace path parameters
  static String buildPath(String path, Map<String, dynamic> params) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}