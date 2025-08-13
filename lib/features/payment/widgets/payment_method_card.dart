import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../models/payment_method.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback? onTap;
  final bool isSelected;

  const PaymentMethodCard({
    Key? key,
    required this.method,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.white,
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon/Logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _buildIcon(),
              ),
            ),
            const SizedBox(width: 16),
            
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isSelected 
                  ? AppColors.primary 
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (method.type) {
      case PaymentMethodType.mpesa:
        return Text(
          'M',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        );
      case PaymentMethodType.paystack:
        return const Icon(
          Icons.credit_card,
          size: 32,
          color: AppColors.white,
        );
    }
  }

  Color _getIconBackgroundColor() {
    switch (method.type) {
      case PaymentMethodType.mpesa:
        return const Color(0xFF4CAF50); // M-Pesa green
      case PaymentMethodType.paystack:
        return const Color(0xFF00ADEF); // Paystack blue
    }
  }
}