import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/features/profile/screens/profile_menu_screen.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';
import 'package:noxxi/features/home/widgets/event_feed.dart';
import 'package:noxxi/features/home/widgets/loaders/event_card_skeleton.dart';
import 'package:noxxi/features/home/models/event_feed_item.dart';
import 'package:noxxi/features/home/services/feed_service.dart';
import 'package:noxxi/features/home/services/event_interactions.dart';

import 'package:share_plus/share_plus.dart';

/// Optimized home screen showing trending events across all categories
/// Uses materialized view for ultra-fast loading
class TrendingHomeScreen extends StatefulWidget {
  const TrendingHomeScreen({super.key});

  @override
  State<TrendingHomeScreen> createState() => _TrendingHomeScreenState();
}

class _TrendingHomeScreenState extends State<TrendingHomeScreen> {
  final _feedService = FeedService();
  final _eventInteractions = EventInteractions();
  
  List<EventFeedItem> _events = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrendingEvents();
  }

  Future<void> _loadTrendingEvents() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isLoading = _events.isEmpty;
      _error = null;
    });

    try {
      // Use the optimized popular events query
      final events = await _feedService.fetchPopularEvents(limit: 20);
      
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load trending events. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEvents() async {
    _isRefreshing = true;
    await _loadTrendingEvents();
    _isRefreshing = false;
  }

  Future<void> _toggleCart(EventFeedItem event) async {
    // Optimistic update
    setState(() {
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event.copyWith(isInCart: !event.isInCart);
      }
    });

    try {
      if (event.isInCart) {
        await _eventInteractions.removeFromCart(event.id);
      } else {
        await _eventInteractions.addToCart(event.id);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          final index = _events.indexWhere((e) => e.id == event.id);
          if (index != -1) {
            _events[index] = event;
          }
        });
      }
    }
  }

  Future<void> _shareEvent(EventFeedItem event) async {
    final shareText = 'Check out "${event.title}" on Noxxi!\n\n'
        '${event.priceRange}\n'
        'Date: ${_formatDate(event.eventDate)}\n'
        'Venue: ${event.venueName}\n\n'
        'Get your tickets now: https://noxxi.app/events/${event.id}';
    
    try {
      await Share.share(shareText, subject: event.title);
      await _eventInteractions.trackShare(event.id);
    } catch (e) {
      debugPrint('Error sharing event: $e');
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

  void _navigateToEventDetails(EventFeedItem event) {
    // TODO: Navigate to event details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${event.title}...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToCategoryPage(String categoryId, String categoryName) {
    Navigator.pushNamed(
      context,
      '/category',
      arguments: {
        'categoryId': categoryId,
        'categoryName': categoryName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Base layer for backdrop effect
          Container(
            color: AppColors.frostedBackground, // #F1F1F1 base
          ),
          // Frosted glass effect with exact specs
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0).withOpacity(0.3), // rgba(240, 240, 240, 0.3)
                border: Border.all(
                  color: Colors.white.withOpacity(0.4), // rgba(255, 255, 255, 0.4)
                  width: 0.5,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildCategoryBar(),
                Expanded(
                  child: _buildEventFeed(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 56.0,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: Colors.black87,
              size: 26,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileMenuScreen(),
                ),
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
  
  Widget _buildCategoryBar() {
    // Main categories
    final mainCategories = [
      {'id': 'events', 'name': 'Events'},
      {'id': 'sports', 'name': 'Sports'},
      {'id': 'cinema', 'name': 'Cinema'},
      {'id': 'experiences', 'name': 'Experiences'},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: LiquidGlassContainer(
          blur: 20, // Blur amount for glass effect
          opacity: 0.15, // Glass opacity
          borderRadius: BorderRadius.circular(25),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: SizedBox(
            height: 21, // Height adjusted for content
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: mainCategories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: InkWell(
                      onTap: () => _navigateToCategoryPage(
                        category['id'] as String,
                        category['name'] as String,
                      ),
                      child: Text(
                        category['name'] as String,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventFeed() {
    if (_isLoading) {
      return const EventFeedSkeleton();
    }

    if (_error != null && _events.isEmpty) {
      return _buildErrorState(_error!);
    }

    return EventFeed(
      events: _events,
      isLoading: false,
      hasMore: false, // No pagination for trending
      onEventTap: _navigateToEventDetails,
      onToggleCart: _toggleCart,
      onShare: _shareEvent,
      onRefresh: _refreshEvents,
      onLoadMore: () async {}, // No load more for trending
    );
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
              onPressed: _loadTrendingEvents,
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
}