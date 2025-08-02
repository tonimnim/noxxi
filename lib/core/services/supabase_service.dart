import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://smlwmbhhpawtfjnmfgqt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtbHdtYmhocGF3dGZqbm1mZ3F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQwNDgwMTEsImV4cCI6MjA2OTYyNDAxMX0.1BBWxPkwCqPdzh8t4oj6rwrDyBMfFaovJfhneihWxJ8';
  
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  // Auth helper
  User? get currentUser => client.auth.currentUser;
  
  // Profile helper
  String? get userId => currentUser?.id;
}

// Global instance
final supabase = SupabaseService().client;