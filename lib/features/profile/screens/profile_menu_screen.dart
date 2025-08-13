import 'package:flutter/material.dart';
import 'package:noxxi/features/profile/services/profile_service.dart';
import 'package:noxxi/features/profile/screens/edit_profile_screen.dart';
import 'package:noxxi/features/profile/screens/payment_methods_screen.dart';
import 'package:noxxi/features/profile/screens/refund_requests_screen.dart';
import 'package:noxxi/features/profile/screens/friends_screen.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({super.key});

  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
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
    ).then((_) => _loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                          
                          Text(
                            _profile?['phone_number'] ?? 'No phone number',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          if (_profile?['city'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _profile!['city'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          
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
                              color: Colors.grey[600],
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
                          
                          _buildMenuItem(
                            icon: Icons.receipt_long,
                            title: 'Purchase History',
                            subtitle: 'View all your past purchases',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Purchase history coming soon')),
                              );
                            },
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
                          
                          _buildMenuItem(
                            icon: Icons.favorite,
                            title: 'Saved Events',
                            subtitle: 'Events you are interested in',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved events coming soon')),
                              );
                            },
                          ),
                          
                          _buildMenuItem(
                            icon: Icons.calendar_today,
                            title: 'Event Calendar',
                            subtitle: 'Your upcoming events',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Event calendar coming soon')),
                              );
                            },
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