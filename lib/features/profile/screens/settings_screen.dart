import 'package:flutter/material.dart';
import 'package:noxxi/features/profile/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:noxxi/core/providers/auth_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _profileService.getSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      _settings[key] = value;
    });
    
    try {
      await _profileService.updateSettings({key: value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setting updated')),
        );
      }
    } catch (e) {
      // Revert on error
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating setting: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      // Double confirmation for account deletion
      final doubleConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: const Text(
            'All your data will be permanently deleted. This includes:\n'
            '• Your profile information\n'
            '• Your tickets\n'
            '• Your payment methods\n'
            '• Your support tickets\n\n'
            'This action CANNOT be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Delete Everything'),
            ),
          ],
        ),
      );
      
      if (doubleConfirm == true) {
        try {
          await _profileService.deleteAccount();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting account: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance Section
                  _buildSectionHeader('APPEARANCE'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Theme'),
                          subtitle: Text(_getThemeText(_settings['theme_preference'] ?? 'light')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showThemeDialog(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Notifications Section
                  _buildSectionHeader('NOTIFICATIONS'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Push Notifications'),
                          subtitle: const Text('Receive event updates and reminders'),
                          value: _settings['notifications_enabled'] ?? true,
                          onChanged: (value) => _updateSetting('notifications_enabled', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Email Notifications'),
                          subtitle: const Text('Receive updates via email'),
                          value: _settings['email_notifications'] ?? false,
                          onChanged: (value) => _updateSetting('email_notifications', value),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('SMS Notifications'),
                          subtitle: const Text('Receive updates via SMS'),
                          value: _settings['sms_notifications'] ?? false,
                          onChanged: (value) => _updateSetting('sms_notifications', value),
                        ),
                      ],
                    ),
                  ),
                  
                  // Privacy Section
                  _buildSectionHeader('PRIVACY'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () {
                            // TODO: Open privacy policy
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Privacy policy coming soon')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description),
                          title: const Text('Terms of Service'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () {
                            // TODO: Open terms of service
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Terms of service coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Account Section
                  _buildSectionHeader('ACCOUNT'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.security),
                          title: const Text('Change PIN'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Implement change PIN
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Change PIN coming soon')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.download),
                          title: const Text('Export My Data'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Implement data export
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Data export coming soon')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: Colors.red),
                          title: const Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.red),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.red),
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  String _getThemeText(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System Default';
      default:
        return 'Light';
    }
  }

  Future<void> _showThemeDialog() async {
    final currentTheme = _settings['theme_preference'] ?? 'light';
    
    final newTheme = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: currentTheme,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: currentTheme,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: currentTheme,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );
    
    if (newTheme != null && newTheme != currentTheme) {
      _updateSetting('theme_preference', newTheme);
    }
  }
}