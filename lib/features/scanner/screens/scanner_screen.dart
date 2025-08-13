import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'QR Scanner',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 24,
              fontFamily: 'Raleway',
            ),
          ),
        ),
      ),
    );
  }
}