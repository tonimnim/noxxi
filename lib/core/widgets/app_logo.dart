import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;
  
  const AppLogo({
    super.key,
    this.fontSize = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Noxxi',
      style: TextStyle(
        fontFamily: 'Biski',
        fontSize: fontSize,
        fontWeight: FontWeight.normal,
        color: color ?? AppColors.primaryText,
        letterSpacing: -1.0,
      ),
    );
  }
}