import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final ApiClient _apiClient = ApiClient.instance;

  // Profile Management
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.currentUser,
      );
      return response;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    String? phoneNumber,
    String? city,
    String? themePreference,
  }) async {
    final updates = <String, dynamic>{};
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (city != null) updates['city'] = city;
    if (themePreference != null) updates['theme_preference'] = themePreference;
    
    if (updates.isNotEmpty) {
      await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.updateProfile,
        data: updates,
      );
    }
  }

  // Payment Methods Management
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.paymentMethods,
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
      return [];
    }
  }

  Future<void> addPaymentMethod({
    required String mpesaPhoneNumber,
    String? mpesaAccountName,
    String? nickname,
    bool isDefault = false,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.paymentMethods,
      data: {
        'type': 'mpesa',
        'mpesa_phone_number': mpesaPhoneNumber,
        'mpesa_account_name': mpesaAccountName,
        'nickname': nickname ?? 'M-Pesa',
        'is_default': isDefault,
      },
    );
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.buildPath(ApiEndpoints.paymentDetails, {'id': paymentMethodId}),
    );
  }

  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.buildPath(ApiEndpoints.paymentDetails, {'id': paymentMethodId}),
      data: {'is_default': true},
    );
  }

  // Refund Requests Management
  Future<List<Map<String, dynamic>>> getRefundRequests() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/refunds',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching refund requests: $e');
      return [];
    }
  }

  Future<String> createRefundRequest({
    required String orderId,
    String? ticketId,
    required String reason,
    String? reasonDetails,
    required double amount,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/refunds',
      data: {
        'order_id': orderId,
        'ticket_id': ticketId,
        'reason': reason,
        'reason_details': reasonDetails,
        'amount': amount,
        'currency': 'KES',
      },
    );

    return response['request_number'] ?? '';
  }

  Future<void> cancelRefundRequest(String refundRequestId) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/refunds/$refundRequestId/cancel',
    );
  }

  // Support Tickets Management
  Future<List<Map<String, dynamic>>> getSupportTickets() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.supportTickets,
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
      return [];
    }
  }

  Future<String> createSupportTicket({
    required String category,
    required String subject,
    required String description,
    String? orderId,
    String priority = 'medium',
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.createSupportTicket,
      data: {
        'category': category,
        'subject': subject,
        'description': description,
        'order_id': orderId,
        'priority': priority,
      },
    );

    return response['ticket_number'] ?? '';
  }

  Future<void> addSupportTicketResponse({
    required String ticketId,
    required String message,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.buildPath(ApiEndpoints.supportTicketDetails, {'id': ticketId}) + '/responses',
      data: {
        'message': message,
      },
    );
  }

  // Friends Management - Stub implementations (not implemented in Laravel API yet)
  Future<List<Map<String, dynamic>>> getFriends() async {
    // TODO: Implement friends API in Laravel backend
    return [];
  }

  Future<List<Map<String, dynamic>>> getPendingFriendRequests() async {
    // TODO: Implement friend requests API in Laravel backend
    return [];
  }

  Future<void> sendFriendRequest(String friendId) async {
    // TODO: Implement send friend request API in Laravel backend
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    // TODO: Implement accept friend request API in Laravel backend
  }

  Future<void> rejectFriendRequest(String friendshipId) async {
    // TODO: Implement reject friend request API in Laravel backend
  }

  Future<void> removeFriend(String friendshipId) async {
    // TODO: Implement remove friend API in Laravel backend
  }

  // Account Management
  Future<void> deleteAccount() async {
    await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.deleteAccount,
    );
    
    // Clear local auth data
    await _apiClient.clearAuthData();
  }

  // Settings Management
  Future<Map<String, dynamic>> getSettings() async {
    final profile = await getCurrentUserProfile();
    if (profile == null) return {'theme_preference': 'light'};
    
    return {
      'theme_preference': profile['theme_preference'] ?? 'light',
      'notifications_enabled': profile['notifications_enabled'] ?? true,
      'email_notifications': profile['email_notifications'] ?? false,
      'sms_notifications': profile['sms_notifications'] ?? false,
    };
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.updateProfile,
      data: settings,
    );
  }
}