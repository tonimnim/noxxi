enum PaymentMethodType { 
  mpesa,
  paystack,
}

class PaymentMethod {
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final String icon;
  final bool isAvailable;

  const PaymentMethod({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isAvailable = true,
  });

  static List<PaymentMethod> getAvailableMethods(String currency) {
    final methods = <PaymentMethod>[];
    
    // M-Pesa for KES (Kenya)
    if (currency == 'KES') {
      methods.add(const PaymentMethod(
        type: PaymentMethodType.mpesa,
        title: 'M-Pesa',
        subtitle: 'Pay with mobile money',
        icon: 'assets/icons/mpesa.png',
      ));
    }
    
    // Paystack for multiple currencies
    if (['NGN', 'GHS', 'ZAR', 'KES', 'USD'].contains(currency)) {
      methods.add(const PaymentMethod(
        type: PaymentMethodType.paystack,
        title: 'Card Payment',
        subtitle: 'Visa, Mastercard, Verve',
        icon: 'assets/icons/card.png',
      ));
    }
    
    return methods;
  }
}

class PaymentResponse {
  final bool success;
  final String? transactionId;
  final String? paymentUrl;
  final String? message;
  final Map<String, dynamic>? data;

  PaymentResponse({
    required this.success,
    this.transactionId,
    this.paymentUrl,
    this.message,
    this.data,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['status'] == 'success',
      transactionId: json['data']?['transaction_id'],
      paymentUrl: json['data']?['payment_url'],
      message: json['message'],
      data: json['data'],
    );
  }
}

class PaymentStatus {
  final String status; // pending, success, failed
  final String transactionId;
  final String? message;
  final Map<String, dynamic>? metadata;

  PaymentStatus({
    required this.status,
    required this.transactionId,
    this.message,
    this.metadata,
  });

  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      status: json['data']?['status'] ?? json['status'],
      transactionId: json['data']?['transaction_id'] ?? '',
      message: json['message'],
      metadata: json['data']?['metadata'],
    );
  }
}