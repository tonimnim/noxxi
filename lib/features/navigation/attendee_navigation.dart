import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/screens/trending_home_screen.dart';
import 'package:noxxi/features/search/screens/search_screen.dart';
import 'package:noxxi/features/cart/screens/cart_screen.dart';
import 'package:noxxi/features/tickets/screens/tickets_screen.dart';
import 'package:noxxi/features/profile/screens/profile_menu_screen.dart';

class AttendeeNavigation extends StatefulWidget {
  final bool isGuest;
  
  const AttendeeNavigation({
    super.key,
    this.isGuest = false,
  });

  @override
  State<AttendeeNavigation> createState() => _AttendeeNavigationState();
}

class _AttendeeNavigationState extends State<AttendeeNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<Widget> _screens = [
    const TrendingHomeScreen(),
    const SearchScreen(),
    const CartScreen(),
    const TicketsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          _screens[_selectedIndex],
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutQuad,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: AppColors.liquidBlur, sigmaY: AppColors.liquidBlur),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.glassGradientStart,
                          AppColors.glassGradientMiddle,
                          AppColors.glassGradientEnd,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                      // Spherical bulge effect behind selected icon
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutQuad,
                        left: _selectedIndex * (MediaQuery.of(context).size.width - 40) / 5 - 10,
                        right: (4 - _selectedIndex) * (MediaQuery.of(context).size.width - 40) / 5 - 10,
                        top: -5,
                        bottom: -5,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              radius: 0.8,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                          _buildNavItem(1, Icons.search_outlined, Icons.search, 'Search'),
                          _buildNavItem(2, Icons.favorite_outline, Icons.favorite, 'Saved'),
                          _buildNavItem(3, Icons.confirmation_number_outlined, Icons.confirmation_number, 'Tickets'),
                        ],
                      ),
                    ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        width: 65,
        padding: EdgeInsets.symmetric(vertical: isSelected ? 6 : 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()
                ..translate(0.0, isSelected ? -2.0 : 0.0)
                ..scale(isSelected ? 1.15 : 1.0),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                size: isSelected ? 28 : 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
