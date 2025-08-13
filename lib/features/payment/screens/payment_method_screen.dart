import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/inputs.dart';
import '../models/payment_method.dart';
import '../services/payment_service.dart';
import '../widgets/payment_method_card.dart';
import 'payment_status_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String currency;

  const PaymentMethodScreen({
    Key? key,
    required this.bookingId,
    required this.amount,
    required this.currency,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final methods = PaymentMethod.getAvailableMethods(widget.currency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
      ),
      body: Column(
        children: [
          // Amount Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: AppColors.primary.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'Total Amount',
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Payment Methods
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Select Payment Method',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 16),
                ...methods.map((method) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PaymentMethodCard(
                    method: method,
                    onTap: _isProcessing 
                      ? null 
                      : () => _handlePaymentMethod(method),
                  ),
                )),
                
                if (methods.isEmpty) ...[
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.payment,
                    size: 64,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payment methods available for ${widget.currency}',
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePaymentMethod(PaymentMethod method) async {
    if (method.type == PaymentMethodType.mpesa) {
      await _handleMpesaPayment();
    } else {
      await _handlePaystackPayment();
    }
  }

  Future<void> _handleMpesaPayment() async {
    // Show phone number input dialog
    final phoneNumber = await showDialog<String>(
      context: context,
      builder: (context) => _PhoneNumberDialog(),
    );

    if (phoneNumber == null || phoneNumber.isEmpty) return;

    setState(() => _isProcessing = true);

    final response = await _paymentService.initializePayment(
      bookingId: widget.bookingId,
      paymentMethod: PaymentMethodType.mpesa,
      phoneNumber: phoneNumber,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (response.success && response.transactionId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentStatusScreen(
            transactionId: response.transactionId!,
            paymentMethod: PaymentMethodType.mpesa,
            amount: widget.amount,
            currency: widget.currency,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Payment initialization failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handlePaystackPayment() async {
    setState(() => _isProcessing = true);

    final response = await _paymentService.initializePayment(
      bookingId: widget.bookingId,
      paymentMethod: PaymentMethodType.paystack,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (response.success) {
      if (response.paymentUrl != null) {
        // TODO: Open WebView with payment URL
        // For now, just show status screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(
              transactionId: response.transactionId ?? '',
              paymentMethod: PaymentMethodType.paystack,
              paymentUrl: response.paymentUrl,
              amount: widget.amount,
              currency: widget.currency,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Payment initialization failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _PhoneNumberDialog extends StatefulWidget {
  @override
  State<_PhoneNumberDialog> createState() => _PhoneNumberDialogState();
}

class _PhoneNumberDialogState extends State<_PhoneNumberDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter M-Pesa Number'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the phone number registered with M-Pesa',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            PhoneInput(
              controller: _controller,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        PrimaryButton(
          text: 'Continue',
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _controller.text);
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}