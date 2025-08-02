import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle event categories
class CategoryService {
  final _supabase = Supabase.instance.client;
  
  // Cache categories to reduce API calls
  List<EventCategory>? _cachedCategories;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  /// Fetch all active categories
  Future<List<EventCategory>> fetchCategories({bool forceRefresh = false}) async {
    // Return cached data if valid
    if (!forceRefresh && 
        _cachedCategories != null && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
      return _cachedCategories!;
    }
    
    try {
      final response = await _supabase
          .from('event_categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      
      _cachedCategories = (response as List)
          .map((json) => EventCategory.fromJson(json))
          .toList();
      _lastFetchTime = DateTime.now();
      
      return _cachedCategories!;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return _cachedCategories ?? [];
    }
  }
  
  /// Get category by ID
  Future<EventCategory?> getCategoryById(String categoryId) async {
    try {
      final categories = await fetchCategories();
      return categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => EventCategory(
          id: categoryId,
          name: 'Unknown',
          slug: 'unknown',
        ),
      );
    } catch (e) {
      debugPrint('Error getting category: $e');
      return null;
    }
  }
  
  /// Get popular categories based on event count
  Future<List<EventCategory>> fetchPopularCategories({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('event_categories')
          .select('''
            *,
            events!inner(id)
          ''')
          .eq('is_active', true)
          .eq('events.status', 'published')
          .gte('events.event_date', DateTime.now().toIso8601String())
          .order('events.count', ascending: false)
          .limit(limit);
      
      return (response as List)
          .map((json) => EventCategory.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching popular categories: $e');
      // Fallback to regular categories
      final allCategories = await fetchCategories();
      return allCategories.take(limit).toList();
    }
  }
  
  /// Clear category cache
  void clearCache() {
    _cachedCategories = null;
    _lastFetchTime = null;
  }
}

/// Event category model
class EventCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final String? color;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  EventCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.color,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });
  
  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      iconUrl: json['icon_url'],
      color: json['color'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon_url': iconUrl,
      'color': color,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  /// Get icon widget based on icon string
  IconData getIconData() {
    // If we have an icon URL, we can't return IconData
    // This method should be used for predefined icons only
    switch (slug) {
      case 'music':
        return Icons.music_note;
      case 'sports':
        return Icons.sports_basketball;
      case 'business':
        return Icons.business_center;
      case 'food':
        return Icons.restaurant;
      case 'art':
        return Icons.palette;
      case 'tech':
        return Icons.computer;
      case 'education':
        return Icons.school;
      case 'health':
        return Icons.health_and_safety;
      case 'charity':
        return Icons.volunteer_activism;
      case 'theater':
        return Icons.theater_comedy;
      case 'party':
        return Icons.celebration;
      case 'outdoor':
        return Icons.nature_people;
      default:
        return Icons.event;
    }
  }
}