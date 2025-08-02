import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noxxi/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStateProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<AuthState>? _authSubscription;
  
  User? _user;
  bool _isLoading = true;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  AuthStateProvider() {
    _initialize();
  }
  
  void _initialize() {
    // Check initial auth state
    _user = _authService.currentUser;
    _isLoading = false;
    notifyListeners();
    
    // Listen to auth state changes
    _authSubscription = _authService.listenToAuthChanges((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          _user = session?.user;
          break;
        case AuthChangeEvent.signedOut:
          _user = null;
          break;
        case AuthChangeEvent.userUpdated:
          _user = session?.user;
          break;
        case AuthChangeEvent.tokenRefreshed:
          _user = session?.user;
          break;
        default:
          break;
      }
      
      notifyListeners();
    });
    
    // Periodically check and refresh token
    Timer.periodic(const Duration(minutes: 5), (_) {
      _authService.checkAndRefreshToken();
    });
  }
  
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    
    // Clear cached user role
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// Global auth state provider
final authStateProvider = AuthStateProvider();