import 'package:flutter/material.dart';
import 'package:noxxi/features/navigation/attendee_navigation.dart';
import 'package:noxxi/features/navigation/organizer_navigation.dart';
import 'package:noxxi/features/navigation/manager_navigation.dart';
import 'package:noxxi/features/auth/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  String _userRole = 'user'; // Default to user
  final AuthService _authService = AuthService();
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    // First, try to load from cache instantly
    final prefs = await SharedPreferences.getInstance();
    final cachedRole = prefs.getString('user_role');
    
    if (cachedRole != null && mounted) {
      setState(() {
        _userRole = cachedRole;
        _roleLoaded = true;
      });
    }
    
    // Then fetch fresh role from database in background
    _fetchAndCacheUserRole();
  }

  Future<void> _fetchAndCacheUserRole() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null && profile['role'] != null) {
        final role = profile['role'] as String;
        
        // Cache the role
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
        
        // Clear role cache on logout
        await prefs.setString('user_id', _authService.userId ?? '');
        
        if (mounted && (role != _userRole || !_roleLoaded)) {
          setState(() {
            _userRole = role;
            _roleLoaded = true;
          });
        }
      }
    } catch (e) {
      // If fetch fails, still mark as loaded to use default
      if (mounted && !_roleLoaded) {
        setState(() {
          _roleLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show navigation immediately based on role
    switch (_userRole) {
      case 'organizer':
        return const OrganizerNavigation();
      case 'manager':
        return const ManagerNavigation();
      case 'user':
      default:
        return const AttendeeNavigation();
    }
  }
}