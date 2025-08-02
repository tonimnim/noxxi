import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle event interactions and analytics
/// Manages saves, cart, shares, and impression tracking
class EventInteractions {
  final _supabase = Supabase.instance.client;
  static const String _cartKey = 'noxxi_cart_items';
  static const String _impressionKey = 'noxxi_tracked_impressions';
  
  /// Get user's cart items from local storage
  Future<Set<String>> getUserCartItems() async {
    return getCartItems();
  }
  
  /// Add event to cart (local storage)
  Future<void> addToCart(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItems = prefs.getStringList(_cartKey) ?? [];
      
      if (!cartItems.contains(eventId)) {
        cartItems.add(eventId);
        await prefs.setStringList(_cartKey, cartItems);
        
        // Track add to cart
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          await _trackInteraction(userId, eventId, 'add_to_cart');
        }
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }
  
  /// Remove event from cart
  Future<void> removeFromCart(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItems = prefs.getStringList(_cartKey) ?? [];
      
      cartItems.remove(eventId);
      await prefs.setStringList(_cartKey, cartItems);
      
      // Track remove from cart
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _trackInteraction(userId, eventId, 'remove_from_cart');
      }
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }
  
  /// Get cart items
  Future<Set<String>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartItems = prefs.getStringList(_cartKey) ?? [];
      return cartItems.toSet();
    } catch (e) {
      debugPrint('Error getting cart items: $e');
      return {};
    }
  }
  
  /// Track share action
  Future<void> trackShare(String eventId) async {
    try {
      // Increment share count in database
      await _supabase.rpc('increment_share_count', params: {
        'event_id': eventId,
      });
      
      // Track share interaction
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _trackInteraction(userId, eventId, 'share');
      }
    } catch (e) {
      debugPrint('Error tracking share: $e');
    }
  }
  
  /// Track event impressions (batch)
  Future<void> trackImpressions(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackedImpressions = prefs.getStringList(_impressionKey) ?? [];
      final newImpressions = <String>[];
      
      // Filter out already tracked impressions
      for (final eventId in eventIds) {
        if (!trackedImpressions.contains(eventId)) {
          newImpressions.add(eventId);
          trackedImpressions.add(eventId);
        }
      }
      
      if (newImpressions.isEmpty) return;
      
      // Save updated tracked list
      await prefs.setStringList(_impressionKey, trackedImpressions);
      
      // Batch increment view counts
      for (final eventId in newImpressions) {
        _supabase.rpc('increment_view_count', params: {
          'event_id': eventId,
        }).then((_) {
          debugPrint('Tracked impression for event: $eventId');
        }).catchError((e) {
          debugPrint('Error tracking impression: $e');
        });
      }
      
      // Track user impressions if logged in
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        for (final eventId in newImpressions) {
          _trackInteraction(userId, eventId, 'impression', priority: false);
        }
      }
    } catch (e) {
      debugPrint('Error tracking impressions: $e');
    }
  }
  
  /// Track user interaction with event
  Future<void> _trackInteraction(
    String userId,
    String eventId,
    String interactionType, {
    bool priority = true,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'event_id': eventId,
        'interaction_type': interactionType,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      if (priority) {
        // Immediate tracking for important actions
        await _supabase.from('event_interactions').insert(data);
      } else {
        // Delayed tracking for less important actions
        Future.delayed(const Duration(seconds: 2), () {
          _supabase.from('event_interactions').insert(data).catchError((e) {
            debugPrint('Error tracking interaction: $e');
          });
        });
      }
    } catch (e) {
      debugPrint('Error tracking interaction: $e');
      if (priority) rethrow;
    }
  }
  
  /// Get interaction analytics for an event
  Future<Map<String, int>> getEventAnalytics(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('view_count, share_count, tickets_sold')
          .eq('id', eventId)
          .single();
      
      // Get cart count from local storage
      final cartItems = await getCartItems();
      final inCartCount = cartItems.contains(eventId) ? 1 : 0;
      
      return {
        'views': response['view_count'] ?? 0,
        'shares': response['share_count'] ?? 0,
        'in_cart': inCartCount,
        'tickets_sold': response['tickets_sold'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting event analytics: $e');
      return {
        'views': 0,
        'shares': 0,
        'in_cart': 0,
        'tickets_sold': 0,
      };
    }
  }
  
  /// Clear impression tracking (for testing/logout)
  Future<void> clearImpressionTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_impressionKey);
    } catch (e) {
      debugPrint('Error clearing impression tracking: $e');
    }
  }
}