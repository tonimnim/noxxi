import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/screens/organizer_home_screen.dart';
import 'package:noxxi/features/search/screens/search_screen.dart';
import 'package:noxxi/features/events/screens/create_event_screen.dart';
import 'package:noxxi/features/cart/screens/cart_screen.dart';
import 'package:noxxi/features/tickets/screens/my_tickets_screen.dart';
import 'package:noxxi/features/scanner/screens/scanner_screen.dart';
import 'package:noxxi/features/profile/screens/profile_screen.dart';

class OrganizerNavigation extends StatefulWidget {
  const OrganizerNavigation({super.key});

  @override
  State<OrganizerNavigation> createState() => _OrganizerNavigationState();
}

class _OrganizerNavigationState extends State<OrganizerNavigation> {
  int _selectedIndex = 0;
  
  // Screens list with null for FAB position
  final List<Widget?> _screens = [
    const OrganizerHomeScreen(),
    const SearchScreen(),
    const CartScreen(),
    null, // FAB position
    const MyTicketsScreen(),
    const ScannerScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      // Navigate to create event (FAB)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateEventScreen()),
      );
    } else {
      setState(() {
        // Adjust index for screens array
        if (index < 3) {
          _selectedIndex = index;
        } else {
          _selectedIndex = index - 1; // Skip FAB position
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home),
                _buildNavItem(1, Icons.search_outlined, Icons.search),
                _buildNavItem(2, Icons.shopping_cart_outlined, Icons.shopping_cart),
                _buildCreateButton(),
                _buildNavItem(4, Icons.confirmation_number_outlined, Icons.confirmation_number),
                _buildNavItem(5, Icons.qr_code_scanner_outlined, Icons.qr_code_scanner),
                _buildNavItem(6, Icons.person_outline, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    // Determine if this item is selected
    bool isSelected = false;
    if (index < 3 && _selectedIndex == index) {
      isSelected = true;
    } else if (index > 3 && _selectedIndex == index - 1) {
      isSelected = true;
    }
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 45,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primaryAccent : AppColors.darkText.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(3),
      child: Container(
        width: 45,
        height: 45,
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
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}