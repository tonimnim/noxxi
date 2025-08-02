import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noxxi/features/home/models/event_feed_item.dart';
import 'package:noxxi/features/home/services/event_interactions.dart';
import 'package:noxxi/features/home/services/feed_service.dart';

/// Controller for event feed with robust state management
/// Handles loading, pagination, user interactions, and error states
class EventFeedController {
  final _supabase = Supabase.instance.client;
  final _stateController = StreamController<EventFeedState>.broadcast();
  final _eventInteractions = EventInteractions();
  final _feedService = FeedService();
  
  EventFeedState _currentState = EventFeedState();
  Timer? _debounceTimer;
  RealtimeChannel? _eventSubscription;
  
  static const int _pageSize = 10;
  static const int _maxRetries = 3;
  
  Stream<EventFeedState> get stateStream => _stateController.stream;
  EventFeedState get currentState => _currentState;
  
  /// Load initial events with retry logic
  Future<void> loadInitialEvents({int retryCount = 0}) async {
    if (_currentState.isInitialLoading) return;
    
    _updateState(_currentState.copyWith(
      isInitialLoading: true,
      error: null,
    ));
    
    try {
      final events = await _feedService.fetchEvents(
        limit: _pageSize,
        sortOrder: EventSortOrder.dateAscending,
      );
      
      // Track impressions for analytics
      _trackEventImpressions(events);
      
      // Subscribe to real-time updates
      _subscribeToEventUpdates();
      
      _updateState(_currentState.copyWith(
        events: events,
        isInitialLoading: false,
        hasMore: events.length >= _pageSize,
        lastDocument: events.isNotEmpty ? events.last.id : null,
        error: null,
      ));
    } catch (e) {
      debugPrint('Error loading events: $e');
      
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return loadInitialEvents(retryCount: retryCount + 1);
      }
      
      _updateState(_currentState.copyWith(
        isInitialLoading: false,
        error: _getErrorMessage(e),
      ));
    }
  }
  
  /// Load more events with optimized pagination
  Future<void> loadMore() async {
    if (_currentState.isLoadingMore || !_currentState.hasMore || _currentState.events.isEmpty) return;
    
    // Debounce rapid scroll requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _updateState(_currentState.copyWith(isLoadingMore: true, error: null));
      
      try {
        final newEvents = await _feedService.fetchEvents(
          limit: _pageSize,
          afterId: _currentState.lastDocument,
          sortOrder: EventSortOrder.dateAscending,
        );
        
        // Track impressions for new events
        _trackEventImpressions(newEvents);
        
        _updateState(_currentState.copyWith(
          events: [..._currentState.events, ...newEvents],
          isLoadingMore: false,
          hasMore: newEvents.length >= _pageSize,
          lastDocument: newEvents.isNotEmpty ? newEvents.last.id : _currentState.lastDocument,
        ));
      } catch (e) {
        debugPrint('Error loading more events: $e');
        _updateState(_currentState.copyWith(
          isLoadingMore: false,
          error: _getErrorMessage(e),
        ));
      }
    });
  }
  
  /// Refresh the feed
  Future<void> refresh() async {
    _currentState = EventFeedState();
    await loadInitialEvents();
  }
  
  /// Toggle cart status with backend sync
  Future<void> toggleCart(EventFeedItem event) async {
    // Optimistic update
    final updatedEvents = _currentState.events.map((e) {
      if (e.id == event.id) {
        return e.copyWith(isInCart: !e.isInCart);
      }
      return e;
    }).toList();
    
    _updateState(_currentState.copyWith(events: updatedEvents));
    
    // Sync with backend
    try {
      if (event.isInCart) {
        await _eventInteractions.removeFromCart(event.id);
      } else {
        await _eventInteractions.addToCart(event.id);
      }
    } catch (e) {
      // Revert on error
      debugPrint('Error updating cart: $e');
      _updateState(_currentState.copyWith(events: _currentState.events));
    }
  }
  
  
  /// Share event with analytics tracking
  Future<void> shareEvent(EventFeedItem event) async {
    final shareText = 'Check out "${event.title}" on Noxxi!\n\n'
        '${event.priceRange}\n'
        'Date: ${_formatDate(event.eventDate)}\n'
        'Venue: ${event.venueName}\n\n'
        'Get your tickets now: https://noxxi.app/events/${event.id}';
    
    try {
      await Share.share(
        shareText,
        subject: event.title,
      );
      
      // Track share action (assume success if no error)
      await _eventInteractions.trackShare(event.id);
      
      // Update local count
      final updatedEvents = _currentState.events.map((e) {
        if (e.id == event.id) {
          return e.copyWith(shareCount: e.shareCount + 1);
        }
        return e;
      }).toList();
      
      _updateState(_currentState.copyWith(events: updatedEvents));
    } catch (e) {
      debugPrint('Error sharing event: $e');
    }
  }
  
  /// Track event impressions for analytics
  void _trackEventImpressions(List<EventFeedItem> events) {
    if (events.isEmpty) return;
    
    // Batch track impressions
    final eventIds = events.map((e) => e.id).toList();
    _eventInteractions.trackImpressions(eventIds);
  }
  
  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'Something went wrong. Please try again later.';
    }
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  void _updateState(EventFeedState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
  
  /// Subscribe to real-time event updates
  void _subscribeToEventUpdates() {
    _eventSubscription?.unsubscribe();
    
    _eventSubscription = _feedService.subscribeToEventUpdates(
      onInsert: (event) {
        // Add new event to top if it matches our filters
        if (event.eventDate.isAfter(DateTime.now())) {
          final updatedEvents = [event, ..._currentState.events];
          _updateState(_currentState.copyWith(events: updatedEvents));
        }
      },
      onUpdate: (event) {
        // Update existing event
        final updatedEvents = _currentState.events.map((e) {
          return e.id == event.id ? event : e;
        }).toList();
        _updateState(_currentState.copyWith(events: updatedEvents));
      },
      onDelete: (eventId) {
        // Remove deleted event
        final updatedEvents = _currentState.events
            .where((e) => e.id != eventId)
            .toList();
        _updateState(_currentState.copyWith(events: updatedEvents));
      },
    );
  }
  
  void dispose() {
    _debounceTimer?.cancel();
    _eventSubscription?.unsubscribe();
    _stateController.close();
  }
}

/// State for event feed
class EventFeedState {
  final List<EventFeedItem> events;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? lastDocument;
  final String? error;
  
  EventFeedState({
    this.events = const [],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDocument,
    this.error,
  });
  
  EventFeedState copyWith({
    List<EventFeedItem>? events,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? lastDocument,
    String? error,
  }) {
    return EventFeedState(
      events: events ?? this.events,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      error: error ?? this.error,
    );
  }
}