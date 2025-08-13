import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/profile/services/profile_service.dart';
import 'package:noxxi/features/profile/screens/edit_profile_screen.dart';
import 'package:noxxi/features/profile/screens/payment_methods_screen.dart';
import 'package:noxxi/features/profile/screens/refund_requests_screen.dart';
import 'package:noxxi/features/profile/screens/friends_screen.dart';
import 'package:noxxi/features/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:noxxi/core/providers/auth_state_provider.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    // Load profile without blocking UI
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getCurrentUserProfile();
    
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => _loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthStateProvider>(context);
    final isGuest = !authState.isAuthenticated;
    
    // Show login prompt for guests
    if (isGuest) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.85 - 20, // Reduce by 20px
        child: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 80,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Guest!',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign in to access all features',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      );
    }
    
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85 - 20, // Reduce by 20px
      child: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            _profile?['phone_number']?.substring(0, 2) ?? 'U',
                            style: GoogleFonts.sora(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                          Text(
                          _profile?['phone_number'] ?? 'No phone number',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                          ),
                        ),
                        
                        if (_profile?['city'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _profile!['city'],
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // Account Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Text(
                            'ACCOUNT',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () => _navigateToScreen(
                            EditProfileScreen(profile: _profile ?? {}),
                          ),
                        ),
                        
                        _buildMenuItem(
                          icon: Icons.credit_card_outlined,
                          title: 'Payment Methods',
                          onTap: () => _navigateToScreen(const PaymentMethodsScreen()),
                        ),
                        
                        _buildMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Refund Requests',
                          onTap: () => _navigateToScreen(const RefundRequestsScreen()),
                        ),
                        
                        _buildMenuItem(
                          icon: Icons.history,
                          title: 'Purchase History',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Purchase history coming soon')),
                            );
                          },
                        ),
                        
                        // Social Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: Text(
                            'SOCIAL',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        _buildMenuItem(
                          icon: Icons.group_outlined,
                          title: 'Friends',
                          onTap: () => _navigateToScreen(const FriendsScreen()),
                        ),
                        
                        _buildMenuItem(
                          icon: Icons.favorite_outline,
                          title: 'Saved Events',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved events coming soon')),
                            );
                          },
                        ),
                        
                        _buildMenuItem(
                          icon: Icons.calendar_today_outlined,
                          title: 'Event Calendar',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event calendar coming soon')),
                            );
                          },
                        ),
                        
                        _buildMenuItem(
                          icon: Icons.share_outlined,
                          title: 'Invite Friends',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invite feature coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: Colors.black87,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}