import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/features/profile/services/profile_service.dart';
import 'package:noxxi/features/auth/services/auth_service.dart';
import 'package:noxxi/features/profile/screens/support_tickets_screen.dart';
import 'package:noxxi/features/profile/screens/settings_screen.dart';

class SettingsBottomNavScreen extends StatelessWidget {
  const SettingsBottomNavScreen({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                // Support Section
                Text(
                  'SUPPORT',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Support Tickets',
                  subtitle: 'Get help with your issues',
                  onTap: () => _navigateToScreen(context, const SupportTicketsScreen()),
                ),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.question_answer,
                  title: 'FAQs',
                  subtitle: 'Frequently asked questions',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('FAQs coming soon')),
                    );
                  },
                ),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.phone,
                  title: 'Contact Us',
                  subtitle: 'Call or email support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact options coming soon')),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // App Section
                Text(
                  'APP',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'App Settings',
                  subtitle: 'Theme, notifications, privacy',
                  onTap: () => _navigateToScreen(context, const SettingsScreen()),
                ),
                
                _buildMenuItem(
                  context: context,
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
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.rate_review,
                  title: 'Rate App',
                  subtitle: 'Rate us on Play Store',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening Play Store...')),
                    );
                  },
                ),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.share,
                  title: 'Share App',
                  subtitle: 'Share with friends',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share functionality coming soon')),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleSignOut(context),
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
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: Colors.black87,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}