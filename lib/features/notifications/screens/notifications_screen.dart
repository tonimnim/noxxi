import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Notifications',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 24,
              fontFamily: 'Raleway',
            ),
          ),
        ),
      ),
    );
  }
}