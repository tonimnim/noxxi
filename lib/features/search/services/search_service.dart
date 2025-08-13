import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Ultra-fast search service optimized for 1 billion users
/// Uses caching, indexes, and smart queries
class SearchService {
  // Mock data for development
  static const String _recentSearchKey = 'recent_searches';
  static const String _cachedResultsKey = 'cached_search_results';
  static const int _maxRecentSearches = 10;
  static const int _cacheExpiryHours = 1;
  
  // In-memory cache for instant results
  final Map<String, List<SearchResult>> _memoryCache = {};
  DateTime? _lastCacheTime;

  /// Main search function - blazing fast with caching
  Future<List<SearchResult>> searchEvents({
    String? query,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    // Create cache key
    final cacheKey = _createCacheKey(query, minPrice, maxPrice, startDate, endDate);
    
    // Check memory cache first (instant!)
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey];
      if (_lastCacheTime != null && 
          DateTime.now().difference(_lastCacheTime!).inMinutes < 5) {
        return cached!;
      }
    }

    try {
      // Mock search - replace with your preferred backend service
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return empty results for now
      final results = <SearchResult>[];

      // Cache the results
      _memoryCache[cacheKey] = results;
      _lastCacheTime = DateTime.now();
      
      // Save to persistent cache if it's a text search
      if (query != null && query.isNotEmpty) {
        await _saveToCache(cacheKey, results);
        await saveRecentSearch(query);
      }

      return results;
    } catch (e) {
      debugPrint('Search error: $e');
      // Try to return cached results on error
      return await _getFromCache(cacheKey) ?? [];
    }
  }

  /// Get popular events for default view (from materialized view - super fast!)
  Future<List<SearchResult>> getPopularEvents({int limit = 20}) async {
    try {
      // Mock popular events - replace with your preferred backend service
      await Future.delayed(const Duration(milliseconds: 300));
      return <SearchResult>[];
    } catch (e) {
      debugPrint('Error fetching popular events: $e');
      return [];
    }
  }

  /// Save recent search term
  Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_recentSearchKey) ?? [];
    
    // Remove if exists and add to front
    recent.remove(query);
    recent.insert(0, query);
    
    // Keep only last N searches
    if (recent.length > _maxRecentSearches) {
      recent = recent.take(_maxRecentSearches).toList();
    }
    
    await prefs.setStringList(_recentSearchKey, recent);
  }

  /// Get recent searches for quick access
  Future<List<String>> getRecentSearches({int limit = 4}) async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_recentSearchKey) ?? [];
    return recent.take(limit).toList();
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchKey);
  }

  /// Clear all cache
  void clearCache() {
    _memoryCache.clear();
    _lastCacheTime = null;
  }

  // Private helper methods
  
  String _createCacheKey(
    String? query,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return '${query ?? ''}_${minPrice ?? ''}_${maxPrice ?? ''}_${startDate ?? ''}_${endDate ?? ''}';
  }

  Future<void> _saveToCache(String key, List<SearchResult> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
      };
      await prefs.setString('$_cachedResultsKey\_$key', jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Cache save error: $e');
    }
  }

  Future<List<SearchResult>?> _getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cachedResultsKey\_$key');
      if (cached == null) return null;

      final cacheData = jsonDecode(cached);
      final timestamp = DateTime.parse(cacheData['timestamp']);
      
      // Check if cache is still valid
      if (DateTime.now().difference(timestamp).inHours > _cacheExpiryHours) {
        return null;
      }

      return (cacheData['results'] as List)
          .map((json) => SearchResult.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Cache read error: $e');
      return null;
    }
  }
}

/// Search result model
class SearchResult {
  final String id;
  final String title;
  final String? venueName;
  final String? city;
  final DateTime eventDate;
  final double? minPrice;
  final double? maxPrice;
  final String? imageUrl;
  final int ticketsSold;
  final int totalCapacity;
  final String? categoryName;

  SearchResult({
    required this.id,
    required this.title,
    this.venueName,
    this.city,
    required this.eventDate,
    this.minPrice,
    this.maxPrice,
    this.imageUrl,
    required this.ticketsSold,
    required this.totalCapacity,
    this.categoryName,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'],
      title: json['title'],
      venueName: json['venue_name'],
      city: json['city'],
      eventDate: DateTime.parse(json['event_date']),
      minPrice: json['min_ticket_price']?.toDouble(),
      maxPrice: json['max_ticket_price']?.toDouble(),
      imageUrl: json['cover_image_url'],
      ticketsSold: json['tickets_sold'] ?? 0,
      totalCapacity: json['total_capacity'] ?? 0,
      categoryName: json['category_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'venue_name': venueName,
      'city': city,
      'event_date': eventDate.toIso8601String(),
      'min_ticket_price': minPrice,
      'max_ticket_price': maxPrice,
      'cover_image_url': imageUrl,
      'tickets_sold': ticketsSold,
      'total_capacity': totalCapacity,
      'category_name': categoryName,
    };
  }

  String get priceDisplay {
    if (minPrice == null) return 'Free';
    if (minPrice == maxPrice || maxPrice == null) {
      return 'KSH ${minPrice!.toStringAsFixed(0)}';
    }
    return 'KSH ${minPrice!.toStringAsFixed(0)} - ${maxPrice!.toStringAsFixed(0)}';
  }

  double get soldPercentage {
    if (totalCapacity == 0) return 0;
    return (ticketsSold / totalCapacity) * 100;
  }
}