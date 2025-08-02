import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/core/providers/auth_state_provider.dart';
import 'package:noxxi/features/auth/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }
  
  Future<void> _signOut() async {
    final authProvider = context.read<AuthStateProvider>();
    await authProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateProvider>();
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text(
          'Noxxi',
          style: TextStyle(
            fontFamily: 'Biski',
            fontSize: 24,
            color: AppColors.primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 16),
              
              if (_userProfile != null) ...[
                Card(
                  color: AppColors.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primaryText,
                            fontFamily: 'Raleway',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Email', _userProfile!['email'] ?? 'N/A'),
                        _buildInfoRow('Phone', _userProfile!['phone_number'] ?? 'N/A'),
                        _buildInfoRow('User Type', _userProfile!['user_type'] ?? 'N/A'),
                        _buildInfoRow(
                          'Member Since',
                          _userProfile!['created_at'] != null
                              ? DateTime.parse(_userProfile!['created_at'])
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0]
                              : 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              Text(
                'Session Info',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'User ID: ${user?.id ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontFamily: 'Raleway',
                ),
              ),
              Text(
                'Session persists even after app restart!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                  fontFamily: 'Raleway',
                ),
              ),
              
              const Spacer(),
              
              Center(
                child: Text(
                  'Your tickets will appear here',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondaryText,
                    fontFamily: 'Raleway',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
              fontFamily: 'Raleway',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}