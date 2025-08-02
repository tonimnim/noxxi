import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/screens/organizer_home_screen.dart';
import 'package:noxxi/features/search/screens/search_screen.dart';
import 'package:noxxi/features/events/screens/create_event_screen.dart';
import 'package:noxxi/features/tickets/screens/my_tickets_screen.dart';
import 'package:noxxi/features/scanner/screens/scanner_screen.dart';

class OrganizerNavigation extends StatefulWidget {
  const OrganizerNavigation({super.key});

  @override
  State<OrganizerNavigation> createState() => _OrganizerNavigationState();
}

class _OrganizerNavigationState extends State<OrganizerNavigation> {
  int _selectedIndex = 0;
  
  final List<Widget?> _screens = [
    const OrganizerHomeScreen(),
    const SearchScreen(),
    null, // FAB - no screen
    const MyTicketsScreen(),
    const ScannerScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Navigate to create event
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateEventScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex < 2 ? _selectedIndex : _selectedIndex > 2 ? _selectedIndex - 1 : 0],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
                _buildNavItem(1, Icons.search_outlined, Icons.search, 'Search'),
                _buildCreateButton(),
                _buildNavItem(3, Icons.confirmation_number_outlined, Icons.confirmation_number, 'Tickets'),
                _buildNavItem(4, Icons.qr_code_scanner_outlined, Icons.qr_code_scanner, 'Scan'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index || (_selectedIndex > 2 && index > 2 && _selectedIndex - 1 == index - 1);
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primaryAccent : AppColors.darkText.withOpacity(0.6),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: AppColors.primaryText,
          size: 28,
        ),
      ),
    );
  }
}