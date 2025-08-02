import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Event',
          style: TextStyle(
            color: AppColors.primaryText,
            fontFamily: 'Raleway',
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Text(
            'Create New Event',
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