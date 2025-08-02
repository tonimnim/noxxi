import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream to listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Current session
  Session? get currentSession => _supabase.auth.currentSession;
  
  // Check if user is logged in
  bool get isLoggedIn => currentSession != null;
  
  // Get user ID
  String? get userId => currentUser?.id;
  
  // Get user email
  String? get userEmail => currentUser?.email;
  
  // Sign in with phone and password (6-digit PIN)
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      // First, we need to implement a custom sign-in since Supabase doesn't 
      // support phone+password directly. We'll use email as the primary auth
      // and store phone in the profile
      
      // For now, we'll use the email from the profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('email')
          .eq('phone_number', phone)
          .maybeSingle();
      
      if (profileResponse == null) {
        throw Exception('Phone number not found. Please register first.');
      }
      
      final email = profileResponse['email'] as String;
      
      // Sign in with email and password
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return response;
    } catch (e) {
      if (e.toString().contains('AuthApiException')) {
        throw Exception('Invalid phone number or PIN');
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  // Send OTP to email
  Future<void> sendOTPToEmail(String email) async {
    await _supabase.auth.signInWithOtp(email: email);
  }
  
  // Verify OTP
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );
  }
  
  // Create user profile after OTP verification
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    // First create the user with password
    await _supabase.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
    
    // Then create/update the profile
    await _supabase.from('profiles').upsert({
      'user_id': userId,
      'email': email,
      'phone_number': phoneNumber,
      'role': 'user',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn || userId == null) return null;
    
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId!)
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (!isLoggedIn || userId == null) {
      throw Exception('User not logged in');
    }
    
    await _supabase
        .from('profiles')
        .update(updates)
        .eq('user_id', userId!);
  }
  
  // Listen to auth state changes
  StreamSubscription<AuthState> listenToAuthChanges(
    void Function(AuthState) onData,
  ) {
    return authStateChanges.listen(onData);
  }
  
  // Refresh session if needed
  Future<void> refreshSession() async {
    if (currentSession != null) {
      await _supabase.auth.refreshSession();
    }
  }
  
  // Check and refresh token if expired
  Future<bool> checkAndRefreshToken() async {
    try {
      final session = currentSession;
      if (session == null) return false;
      
      // Check if token is about to expire (within 5 minutes)
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeUntilExpiry = expiresAt - now;
        
        if (timeUntilExpiry < 300) { // Less than 5 minutes
          await refreshSession();
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}