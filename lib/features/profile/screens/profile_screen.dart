import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/profile/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:noxxi/core/providers/auth_state_provider.dart';
import 'package:noxxi/features/profile/screens/payment_methods_screen.dart';
import 'package:noxxi/features/profile/screens/refund_requests_screen.dart';
import 'package:noxxi/features/profile/screens/support_tickets_screen.dart';
import 'package:noxxi/features/profile/screens/friends_screen.dart';
import 'package:noxxi/features/profile/screens/settings_screen.dart';
import 'package:noxxi/features/profile/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    final profile = await _profileService.getCurrentUserProfile();
    
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => _loadProfile()); // Reload profile when returning
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Profile Picture
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.primaryColor,
                            child: Text(
                              _profile?['phone_number']?.substring(0, 2) ?? 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Number
                          Text(
                            _profile?['phone_number'] ?? 'No phone number',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          // Location
                          if (_profile?['city'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                             _profile!['city'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                          
                          // Edit Profile Button
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _navigateToScreen(
                              EditProfileScreen(profile: _profile ?? {}),
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Menu Items
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Account Section
                          Text(
                            'ACCOUNT',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          _buildMenuItem(
                            icon: Icons.credit_card,
                            title: 'Payment Methods',
                            subtitle: 'Manage your M-Pesa numbers',
                            onTap: () => _navigateToScreen(const PaymentMethodsScreen()),
                          ),
                          
                          _buildMenuItem(
                            icon: Icons.currency_exchange,
                            title: 'Refund Requests',
                            subtitle: 'View and manage refunds',
                            onTap: () => _navigateToScreen(const RefundRequestsScreen()),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Social Section
                          Text(
                            'SOCIAL',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          _buildMenuItem(
                            icon: Icons.group,
                            title: 'Friends',
                            subtitle: 'Manage your friends list',
                            onTap: () => _navigateToScreen(const FriendsScreen()),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Support Section
                          Text(
                            'SUPPORT',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            title: 'Support Tickets',
                            subtitle: 'Get help with your issues',
                            onTap: () => _navigateToScreen(const SupportTicketsScreen()),
                          ),
                          
                          _buildMenuItem(
                            icon: Icons.question_answer,
                            title: 'FAQs',
                            subtitle: 'Frequently asked questions',
                            onTap: () {
                              // TODO: Implement FAQs screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('FAQs coming soon')),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // App Section
                          Text(
                            'APP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          _buildMenuItem(
                            icon: Icons.settings,
                            title: 'Settings',
                            subtitle: 'App preferences and privacy',
                            onTap: () => _navigateToScreen(const SettingsScreen()),
                          ),
                          
                          _buildMenuItem(
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'App version and legal',
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'Noxxi',
                                applicationVersion: '1.0.0',
                                applicationLegalese: '© 2024 Noxxi. All rights reserved.',
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Sign Out Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleSignOut,
                              icon: const Icon(Icons.logout),
                              label: const Text('Sign Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
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
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}