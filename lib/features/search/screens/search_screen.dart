import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Search Events',
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