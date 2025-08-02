import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'My Tickets',
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