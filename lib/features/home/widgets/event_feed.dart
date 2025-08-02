import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:noxxi/features/home/models/event_feed_item.dart';
import 'package:noxxi/features/home/widgets/event_card.dart';
import 'package:noxxi/features/home/widgets/animations/custom_refresh_indicator.dart';
import 'package:noxxi/core/services/image_cache_manager.dart';

/// Instagram-style event feed with scroll controller
/// Vertical scrolling list with pagination support
class EventFeed extends StatefulWidget {
  final List<EventFeedItem> events;
  final Function(EventFeedItem) onEventTap;
  final Function(EventFeedItem) onToggleCart;
  final Function(EventFeedItem)? onShare;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  
  const EventFeed({
    super.key,
    required this.events,
    required this.onEventTap,
    required this.onToggleCart,
    this.onShare,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
  });

  @override
  State<EventFeed> createState() => _EventFeedState();
}

class _EventFeedState extends State<EventFeed> {
  late ScrollController _scrollController;
  final _cacheManager = ImageCacheManager();
  bool _isLoadingMore = false;
  int _lastPreloadIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Initialize cache manager
    _cacheManager.init();
    
    // Preload initial images after ensuring scroll controller is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _preloadUpcomingImages();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isLoadingMore) return;
    
    // Update scroll velocity
    _scrollController.updateVelocity();
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Preload images when user scrolls
    _preloadUpcomingImages();
    
    // Trigger when 80% scrolled
    if (currentScroll >= maxScroll * 0.8) {
      if (widget.hasMore && widget.onLoadMore != null && !widget.isLoading) {
        setState(() => _isLoadingMore = true);
        widget.onLoadMore!();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isLoadingMore = false);
        });
      }
    }
  }
  
  void _preloadUpcomingImages() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.isFastScrolling) return;
    
    // Calculate visible range
    final itemHeight = 400.0; // Approximate height of event card
    final visibleHeight = _scrollController.position.viewportDimension;
    final scrollOffset = _scrollController.position.pixels;
    
    final firstVisibleIndex = (scrollOffset / itemHeight).floor();
    final lastVisibleIndex = ((scrollOffset + visibleHeight) / itemHeight).ceil();
    
    // Preload next 3 images beyond visible range
    final preloadStart = lastVisibleIndex;
    final preloadEnd = (lastVisibleIndex + 3).clamp(0, widget.events.length);
    
    if (preloadStart != _lastPreloadIndex) {
      _lastPreloadIndex = preloadStart;
      
      final imageUrls = <String>[];
      for (int i = preloadStart; i < preloadEnd; i++) {
        if (i < widget.events.length) {
          final imageUrl = widget.events[i].coverImageUrl;
          if (imageUrl.isNotEmpty) {
            imageUrls.add(imageUrl);
          }
        }
      }
      
      if (imageUrls.isNotEmpty && mounted) {
        _cacheManager.preloadImages(imageUrls, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty && !widget.isLoading) {
      return _buildEmptyState();
    }

    return NoxxiRefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: widget.events.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index == widget.events.length) {
            return _buildLoadingIndicator();
          }

          // Event card with scroll controller for performance
          final event = widget.events[index];
          return EventCard(
            key: ValueKey(event.id),
            event: event,
            onTap: () => widget.onEventTap(event),
            onToggleCart: () => widget.onToggleCart(event),
            onShare: widget.onShare != null ? () => widget.onShare!(event) : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.primaryAccent,
      backgroundColor: AppColors.scaffoldBackground,
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: AppColors.darkText.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for exciting events!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkText.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryAccent,
        ),
      ),
    );
  }
}