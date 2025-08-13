import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/screens/trending_home_screen.dart';
import 'package:noxxi/features/search/screens/search_screen.dart';
import 'package:noxxi/features/cart/screens/cart_screen.dart';
import 'package:noxxi/features/tickets/screens/tickets_screen.dart';
import 'package:noxxi/features/profile/screens/settings_bottom_nav_screen.dart';
import 'package:noxxi/features/profile/widgets/profile_drawer.dart';

class AttendeeNavigationWithDrawer extends StatefulWidget {
  const AttendeeNavigationWithDrawer({super.key});

  @override
  State<AttendeeNavigationWithDrawer> createState() => _AttendeeNavigationWithDrawerState();
}

class _AttendeeNavigationWithDrawerState extends State<AttendeeNavigationWithDrawer> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<Widget> _screens = [
    const TrendingHomeScreen(),
    const SearchScreen(),
    const CartScreen(),
    const TicketsScreen(),
    const SettingsBottomNavScreen(),
  ];

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ProfileDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens.asMap().entries.map((entry) {
          final index = entry.key;
          final screen = entry.value;
          
          // Wrap the home screen to add drawer opening capability
          if (index == 0) {
            return NotificationListener<DrawerOpenNotification>(
              onNotification: (notification) {
                openDrawer();
                return true;
              },
              child: screen,
            );
          }
          return screen;
        }).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.search_outlined, Icons.search, 'Search'),
                _buildNavItem(2, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart'),
                _buildNavItem(3, Icons.confirmation_number_outlined, Icons.confirmation_number, 'Tickets'),
                _buildNavItem(4, Icons.settings_outlined, Icons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 65,
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
}

// Custom notification to trigger drawer opening
class DrawerOpenNotification extends Notification {}