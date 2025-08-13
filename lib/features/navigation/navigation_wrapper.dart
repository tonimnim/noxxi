import 'package:flutter/material.dart';
import 'package:noxxi/features/navigation/attendee_navigation.dart';
import 'package:noxxi/features/navigation/organizer_navigation.dart';
import 'package:noxxi/features/navigation/manager_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:noxxi/core/providers/auth_state_provider.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  String _userRole = 'user'; // Default to user
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    // Check if user is authenticated
    final authState = Provider.of<AuthStateProvider>(context, listen: false);
    
    if (!authState.isAuthenticated) {
      // User is not authenticated, use guest mode
      setState(() {
        _userRole = 'guest';
        _roleLoaded = true;
      });
      return;
    }
    
    // Load role from cached user data
    final prefs = await SharedPreferences.getInstance();
    final cachedRole = prefs.getString('user_role');
    
    if (cachedRole != null && mounted) {
      setState(() {
        _userRole = cachedRole;
        _roleLoaded = true;
      });
    } else if (authState.user != null) {
      // Use role from user entity
      setState(() {
        _userRole = authState.user!.role;
        _roleLoaded = true;
      });
    } else {
      // Default to attendee if no role found
      setState(() {
        _userRole = 'attendee';
        _roleLoaded = true;
      });
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
      case 'guest':
        // Guest users get the same navigation but with limited features
        return const AttendeeNavigation(isGuest: true);
      case 'user':
      case 'attendee':
      default:
        return const AttendeeNavigation();
    }
  }
}