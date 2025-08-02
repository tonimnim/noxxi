import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noxxi/features/home/models/event_feed_item.dart';

/// Service to handle event feed API calls
/// Direct Supabase integration for production
class FeedService {
  final _supabase = Supabase.instance.client;
  
  /// Fetch events with various filters
  Future<List<EventFeedItem>> fetchEvents({
    required int limit,
    String? afterId,
    String? categoryId,
    String? searchQuery,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    bool featuredOnly = false,
    String? organizerId,
    EventSortOrder sortOrder = EventSortOrder.dateAscending,
  }) async {
    try {
      var query = _supabase
          .from('events')
          .select('''
            *,
            category:event_categories(id, name, icon_url)
          ''')
          .eq('status', 'published');
      
      // Apply filters
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      
      if (city != null) {
        query = query.ilike('city', '%$city%');
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%,venue_name.ilike.%$searchQuery%');
      }
      
      if (featuredOnly) {
        query = query.eq('featured', true);
      }
      
      if (organizerId != null) {
        query = query.eq('organizer_id', organizerId);
      }
      
      // Date filters
      final now = DateTime.now();
      if (startDate != null) {
        query = query.gte('event_date', startDate.toIso8601String());
      } else {
        // Default: show future events
        query = query.gte('event_date', now.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('event_date', endDate.toIso8601String());
      }
      
      // Pagination
      if (afterId != null) {
        query = query.gt('id', afterId);
      }
      
      // Apply sorting and limit in one chain
      final response = await query
          .order('featured', ascending: false)
          .order(sortOrder == EventSortOrder.dateAscending || sortOrder == EventSortOrder.dateDescending ? 'event_date' : 
                 sortOrder == EventSortOrder.popularity ? 'tickets_sold' :
                 sortOrder == EventSortOrder.priceAscending || sortOrder == EventSortOrder.priceDescending ? 'min_ticket_price' :
                 sortOrder == EventSortOrder.newest ? 'created_at' : 'event_date',
                 ascending: sortOrder == EventSortOrder.dateAscending || sortOrder == EventSortOrder.priceAscending)
          .limit(limit);
      
      // Get user's cart items
      Set<String> cartEventIds = await _getCartEventIds();
      
      return (response as List).map((json) {
        final event = EventFeedItem.fromJson(json);
        return event.copyWith(
          isInCart: cartEventIds.contains(event.id),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      rethrow;
    }
  }
  
  /// Fetch single event details
  Future<EventFeedItem?> fetchEventDetails(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('''
            *,
            category:event_categories(id, name, icon_url)
          ''')
          .eq('id', eventId)
          .single();
      
      bool isInCart = await _isEventInCart(eventId);
      
      final event = EventFeedItem.fromJson(response);
      return event.copyWith(
        isInCart: isInCart,
      );
    } catch (e) {
      debugPrint('Error fetching event details: $e');
      return null;
    }
  }
  
  /// Fetch events by category
  Future<List<EventFeedItem>> fetchEventsByCategory(
    String categoryId, {
    int limit = 20,
    String? afterId,
  }) async {
    return fetchEvents(
      limit: limit,
      afterId: afterId,
      categoryId: categoryId,
    );
  }
  
  /// Fetch featured events
  Future<List<EventFeedItem>> fetchFeaturedEvents({int limit = 10}) async {
    return fetchEvents(
      limit: limit,
      featuredOnly: true,
      sortOrder: EventSortOrder.dateAscending,
    );
  }
  
  /// Fetch trending events (most tickets sold in last 7 days)
  Future<List<EventFeedItem>> fetchTrendingEvents({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('events')
          .select('''
            *,
            category:event_categories(id, name, icon_url)
          ''')
          .eq('status', 'published')
          .gte('event_date', DateTime.now().toIso8601String())
          .order('tickets_sold', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((json) => EventFeedItem.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching trending events: $e');
      return [];
    }
  }
  
  /// Fetch upcoming events for a specific organizer
  Future<List<EventFeedItem>> fetchOrganizerEvents(
    String organizerId, {
    int limit = 20,
  }) async {
    return fetchEvents(
      limit: limit,
      organizerId: organizerId,
      sortOrder: EventSortOrder.dateAscending,
    );
  }
  
  /// Subscribe to real-time event updates
  RealtimeChannel subscribeToEventUpdates({
    required Function(EventFeedItem) onInsert,
    required Function(EventFeedItem) onUpdate,
    required Function(String) onDelete,
  }) {
    return _supabase
        .channel('public:events')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            final event = EventFeedItem.fromJson(payload.newRecord);
            onInsert(event);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            final event = EventFeedItem.fromJson(payload.newRecord);
            onUpdate(event);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            onDelete(payload.oldRecord['id'] as String);
          },
        )
        .subscribe();
  }
  
  
  /// Get cart event IDs from local storage
  Future<Set<String>> _getCartEventIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItems = prefs.getStringList('noxxi_cart_items') ?? [];
      return cartItems.toSet();
    } catch (e) {
      debugPrint('Error getting cart items: $e');
      return {};
    }
  }
  
  /// Check if event is in cart
  Future<bool> _isEventInCart(String eventId) async {
    final cartItems = await _getCartEventIds();
    return cartItems.contains(eventId);
  }
}

/// Event sort order options
enum EventSortOrder {
  dateAscending,
  dateDescending,
  popularity,
  priceAscending,
  priceDescending,
  newest,
}