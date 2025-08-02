import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:noxxi/core/providers/auth_state_provider.dart';
import 'package:noxxi/features/auth/screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget authenticatedWidget;
  
  const AuthWrapper({
    super.key,
    required this.authenticatedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateProvider>(
      builder: (context, authState, child) {
        if (authState.isLoading) {
          // Still checking auth state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (authState.isAuthenticated) {
          return authenticatedWidget;
        }
        
        // Not authenticated, show login
        return const LoginScreen();
      },
    );
  }
}