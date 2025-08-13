import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/loading.dart';
import '../models/payment_method.dart';
import '../services/payment_service.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String transactionId;
  final PaymentMethodType paymentMethod;
  final String? paymentUrl;
  final double amount;
  final String currency;

  const PaymentStatusScreen({
    Key? key,
    required this.transactionId,
    required this.paymentMethod,
    this.paymentUrl,
    required this.amount,
    required this.currency,
  }) : super(key: key);

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  final PaymentService _paymentService = PaymentService();
  StreamSubscription<PaymentStatus>? _statusSubscription;
  PaymentStatus? _currentStatus;
  bool _isPolling = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _statusSubscription = _paymentService
        .pollPaymentStatus(widget.transactionId)
        .listen((status) {
      setState(() {
        _currentStatus = status;
        _isPolling = status.isPending;
      });

      if (status.isSuccess) {
        _onPaymentSuccess();
      } else if (status.isFailed) {
        _onPaymentFailed();
      }
    });
  }

  void _onPaymentSuccess() {
    _statusSubscription?.cancel();
    // Navigate to success or tickets
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/tickets',
          (route) => route.isFirst,
        );
      }
    });
  }

  void _onPaymentFailed() {
    _statusSubscription?.cancel();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isPolling,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentStatus == null || _currentStatus!.isPending)
                  _buildPendingView()
                else if (_currentStatus!.isSuccess)
                  _buildSuccessView()
                else
                  _buildFailedView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingView() {
    return Column(
      children: [
        const LoadingWidget(size: 80),
        const SizedBox(height: 32),
        Text(
          widget.paymentMethod == PaymentMethodType.mpesa
              ? 'Waiting for M-Pesa confirmation'
              : 'Processing payment...',
          style: AppTextStyles.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (widget.paymentMethod == PaymentMethodType.mpesa) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 48,
                  color: AppColors.info,
                ),
                const SizedBox(height: 16),
                Text(
                  'Check your phone',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your M-Pesa PIN on the prompt that appears on your phone',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Transaction ID: ${widget.transactionId}',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 60,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Payment Successful!',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Transaction ID: ${widget.transactionId}',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Redirecting to your tickets...',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildFailedView() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error, width: 2),
          ),
          child: const Icon(
            Icons.close,
            size: 60,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Payment Failed',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _currentStatus?.message ?? 'The payment could not be completed',
          style: AppTextStyles.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Try Again',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          text: 'Cancel',
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ],
    );
  }
}