import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/features/home/widgets/event_feed.dart';
import 'package:noxxi/features/home/controllers/event_feed_controller.dart';
import 'package:noxxi/features/home/widgets/loaders/event_card_skeleton.dart';
import 'package:noxxi/features/home/widgets/category_selector.dart';
import 'package:noxxi/features/home/models/event_feed_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Home screen with event feed
/// Instagram-style vertical scrolling feed
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late EventFeedController _controller;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _controller = EventFeedController();
    _controller.loadInitialEvents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: StreamBuilder<EventFeedState>(
        stream: _controller.stateStream,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _controller.currentState;
          
          if (state.isInitialLoading) {
            return Column(
              children: [
                // Show skeleton for category selector
                CategorySelector(
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (_) {},
                  isLoading: true,
                ),
                // Show skeleton for event feed
                const Expanded(
                  child: EventFeedSkeleton(),
                ),
              ],
            );
          }
          
          // Show error if present
          if (state.error != null && state.events.isEmpty) {
            return _buildErrorState(state.error!);
          }

          return Stack(
            children: [
              Column(
                children: [
                  // Category selector
                  CategorySelector(
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: _onCategorySelected,
                  ),
                  
                  // Event feed
                  Expanded(
                    child: EventFeed(
                      events: state.events,
                      isLoading: state.isLoadingMore,
                      hasMore: state.hasMore,
                      onEventTap: (event) => _navigateToEventDetails(event),
                      onToggleCart: (event) => _controller.toggleCart(event),
                      onShare: (event) => _controller.shareEvent(event),
                      onRefresh: () => _controller.refresh(),
                      onLoadMore: () => _controller.loadMore(),
                    ),
                  ),
                ],
              ),
              
              // Show error banner if error during operation
              if (state.error != null && state.events.isNotEmpty)
                _buildErrorBanner(state.error!),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    final user = Supabase.instance.client.auth.currentUser;
    
    return AppBar(
      backgroundColor: AppColors.scaffoldBackground,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: GestureDetector(
          onTap: () {
            // TODO: Navigate to profile
          },
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryAccent,
              image: user?.userMetadata?['avatar_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(user!.userMetadata!['avatar_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user?.userMetadata?['avatar_url'] == null
                ? Center(
                    child: Text(
                      _getInitial(user),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
      leadingWidth: 72,
      centerTitle: false,
      actions: [
        // Location selector (future feature)
        TextButton.icon(
          onPressed: () {
            // TODO: Implement location selector
          },
          icon: Icon(
            Icons.location_on_outlined,
            size: 18,
            color: AppColors.darkText.withOpacity(0.7),
          ),
          label: Text(
            'Nairobi',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _navigateToEventDetails(event) {
    // TODO: Navigate to event details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${event.title}...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getInitial(User? user) {
    if (user == null) return 'U';
    
    // Try to get initial from phone
    final phone = user.phone ?? '';
    if (phone.isNotEmpty) {
      // Get last digit of phone number
      return phone[phone.length - 1];
    }
    
    // Try email
    final email = user.email ?? '';
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    
    // Try name from metadata
    final name = user.userMetadata?['name'] ?? '';
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    
    // Default
    return 'U';
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.sora(
                fontSize: 14,
                color: AppColors.darkText.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _controller.loadInitialEvents(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.sora(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorBanner(String error) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: AppColors.error,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Clear error by refreshing state
                    _controller.refresh();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  List<EventFeedItem> _getTodayEvents(List<EventFeedItem> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return events.where((event) {
      return event.eventDate.isAfter(today) && 
             event.eventDate.isBefore(tomorrow);
    }).toList();
  }
}