import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Cart',
            style: GoogleFonts.sora(
              color: AppColors.darkText,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}