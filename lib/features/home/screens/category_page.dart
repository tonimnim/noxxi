import 'package:flutter/material.dart';
import 'package:noxxi/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noxxi/features/home/widgets/event_feed.dart';
import 'package:noxxi/features/home/widgets/loaders/event_card_skeleton.dart';
import 'package:noxxi/features/home/widgets/category/subcategory_selector.dart';
import 'package:noxxi/features/home/widgets/category/category_empty_state.dart';
import 'package:noxxi/features/home/widgets/category/category_error_state.dart';
import 'package:noxxi/features/home/models/event_feed_item.dart';
import 'package:noxxi/features/home/services/feed_service.dart';
import 'package:noxxi/features/home/services/event_interactions.dart';
import 'package:noxxi/features/home/services/category_state_manager.dart';
import 'package:noxxi/features/home/services/category_service.dart';
import 'package:share_plus/share_plus.dart';

/// Category page with horizontal subcategory selector and filtered events
/// Maintains state across navigation for seamless experience
class CategoryPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _feedService = FeedService();
  final _categoryService = CategoryService();
  final _eventInteractions = EventInteractions();
  final _stateManager = CategoryStateManager();
  
  List<EventFeedItem> _events = [];
  List<CategoryItem> _subcategories = [];
  String? _selectedSubcategoryId;
  bool _isLoadingEvents = true;
  bool _isLoadingSubcategories = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _lastEventId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCategory();
  }

  Future<void> _initializeCategory() async {
    // Load subcategories
    await _loadSubcategories();
    
    // Restore or set selected subcategory
    final savedSubcategory = _stateManager.getSelectedSubcategory(widget.categoryId);
    if (savedSubcategory != null && _subcategories.any((s) => s.id == savedSubcategory)) {
      _selectedSubcategoryId = savedSubcategory;
    } else if (_subcategories.isNotEmpty) {
      // Default to "All" or first subcategory
      _selectedSubcategoryId = null; // null means "All"
    }
    
    // Load events for selected subcategory
    await _loadEvents();
  }

  Future<void> _loadSubcategories() async {
    // Check cache first
    final cached = _stateManager.getCachedSubcategories(widget.categoryId);
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _subcategories = cached;
        _isLoadingSubcategories = false;
      });
      return;
    }

    try {
      final subcategories = await _categoryService.getSubcategories(widget.categoryId);
      
      // Cache for future use
      _stateManager.cacheSubcategories(widget.categoryId, subcategories);
      
      if (mounted) {
        setState(() {
          _subcategories = subcategories;
          _isLoadingSubcategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSubcategories = false;
        });
      }
    }
  }

  Future<void> _loadEvents({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _events.clear();
        _lastEventId = null;
        _hasMore = true;
      });
    }

    setState(() {
      _isLoadingEvents = _events.isEmpty;
      _error = null;
    });

    try {
      // Determine which category ID to use
      final categoryFilter = _selectedSubcategoryId ?? widget.categoryId;
      
      final events = await _feedService.fetchEvents(
        limit: 20,
        categoryId: categoryFilter,
        afterId: refresh ? null : _lastEventId,
        sortOrder: EventSortOrder.dateAscending,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _events = events;
          } else {
            _events.addAll(events);
          }
          _isLoadingEvents = false;
          _hasMore = events.length >= 20;
          if (events.isNotEmpty) {
            _lastEventId = events.last.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load events. Please try again.';
          _isLoadingEvents = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadEvents();

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _selectSubcategory(String? subcategoryId) {
    if (_selectedSubcategoryId == subcategoryId) return;

    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });

    // Save selection
    _stateManager.setSelectedSubcategory(widget.categoryId, subcategoryId);

    // Reload events for new subcategory
    _loadEvents(refresh: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          SubcategorySelector(
            subcategories: _subcategories,
            selectedSubcategoryId: _selectedSubcategoryId,
            onSubcategorySelected: _selectSubcategory,
            isLoading: _isLoadingSubcategories,
          ),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }


  Widget _buildEventList() {
    if (_isLoadingEvents) {
      return const EventFeedSkeleton();
    }

    if (_error != null && _events.isEmpty) {
      return CategoryErrorState(
        error: _error!,
        onRetry: () => _loadEvents(refresh: true),
      );
    }

    if (_events.isEmpty) {
      return CategoryEmptyState(
        categoryName: widget.categoryName,
        subcategoryName: _selectedSubcategoryId != null
            ? _subcategories.firstWhere((s) => s.id == _selectedSubcategoryId).name
            : null,
      );
    }

    return EventFeed(
      events: _events,
      isLoading: _isLoadingMore,
      hasMore: _hasMore,
      onEventTap: _navigateToEventDetails,
      onToggleCart: _toggleCart,
      onShare: _shareEvent,
      onRefresh: () => _loadEvents(refresh: true),
      onLoadMore: _loadMore,
    );
  }

}