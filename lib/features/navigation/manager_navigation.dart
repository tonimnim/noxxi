import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/screens/attendee_home_screen.dart';
import 'package:noxxi/features/search/screens/search_screen.dart';
import 'package:noxxi/features/cart/screens/cart_screen.dart';
import 'package:noxxi/features/tickets/screens/my_tickets_screen.dart';
import 'package:noxxi/features/scanner/screens/scanner_screen.dart';
import 'package:noxxi/features/profile/screens/profile_screen.dart';

class ManagerNavigation extends StatefulWidget {
  const ManagerNavigation({super.key});

  @override
  State<ManagerNavigation> createState() => _ManagerNavigationState();
}

class _ManagerNavigationState extends State<ManagerNavigation> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const AttendeeHomeScreen(), // Managers see regular home
    const SearchScreen(),
    const CartScreen(),
    const MyTicketsScreen(),
    const ScannerScreen(),
    const ProfileScreen(),
  ];

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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home),
                _buildNavItem(1, Icons.search_outlined, Icons.search),
                _buildNavItem(2, Icons.shopping_cart_outlined, Icons.shopping_cart),
                _buildNavItem(3, Icons.confirmation_number_outlined, Icons.confirmation_number),
                _buildNavItem(4, Icons.qr_code_scanner_outlined, Icons.qr_code_scanner),
                _buildNavItem(5, Icons.person_outline, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 55,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primaryAccent : AppColors.darkText.withOpacity(0.6),
          size: 26,
        ),
      ),
    );
  }
}