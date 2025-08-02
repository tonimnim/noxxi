import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom refresh indicator with Noxxi branding
class NoxxiRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  
  const NoxxiRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryAccent,
      backgroundColor: AppColors.scaffoldBackground,
      strokeWidth: 3,
      displacement: 60,
      child: child,
    );
  }
}

