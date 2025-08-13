import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/payment_method.dart';

class PaymentService {
  final ApiClient apiClient;

  PaymentService({ApiClient? apiClient}) 
    : apiClient = apiClient ?? ApiClient.instance;

  /// Initialize payment with Laravel backend
  /// Laravel decides which gateway to use based on payment method
  Future<PaymentResponse> initializePayment({
    required String bookingId,
    required PaymentMethodType paymentMethod,
    String? phoneNumber, // Required for M-Pesa
  }) async {
    try {
      final endpoint = paymentMethod == PaymentMethodType.mpesa
          ? ApiEndpoints.initializeMpesa
          : ApiEndpoints.initializePaystack;

      final response = await apiClient.post<Map<String, dynamic>>(
        endpoint,
        data: {
          'booking_id': bookingId,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      return PaymentResponse.fromJson(response);
    } catch (e) {
      return PaymentResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Verify payment status from Laravel
  Future<PaymentStatus> verifyPayment(String transactionId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.buildPath(
          ApiEndpoints.paymentDetails,
          {'id': transactionId},
        ),
      );

      return PaymentStatus.fromJson(response);
    } catch (e) {
      return PaymentStatus(
        status: 'failed',
        transactionId: transactionId,
        message: e.toString(),
      );
    }
  }

  /// Poll payment status (for M-Pesa STK push)
  Stream<PaymentStatus> pollPaymentStatus(
    String transactionId, {
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 20,
  }) async* {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      final status = await verifyPayment(transactionId);
      yield status;
      
      if (status.isSuccess || status.isFailed) {
        break;
      }
      
      await Future.delayed(interval);
      attempts++;
    }
  }
}