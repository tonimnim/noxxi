import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AuthStateProvider extends ChangeNotifier {
  UserEntity? _user;
  bool _isLoading = true;
  String? _authToken;
  
  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _authToken != null;
  String? get authToken => _authToken;
  
  AuthStateProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    // Load saved user data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _authToken = token;
      // Try to load user data
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');
      
      if (userId != null) {
        // Create a minimal user entity from cached data
        // Full user data will be loaded when needed
        _user = UserEntity(
          id: int.tryParse(userId) ?? 0,
          fullName: userName ?? '',
          email: userEmail ?? '',
          phoneNumber: userPhone,
          role: UserRole.attendee,
          emailVerified: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> setUser(UserEntity user, String token) async {
    _user = user;
    _authToken = token;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_phone', user.phone);
    await prefs.setString('user_role', user.role);
    
    notifyListeners();
  }
  
  Future<void> signOut() async {
    _user = null;
    _authToken = null;
    
    // Clear cached data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    
    notifyListeners();
  }
  
  void updateUser(UserEntity user) {
    _user = user;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

// Global auth state provider
final authStateProvider = AuthStateProvider();