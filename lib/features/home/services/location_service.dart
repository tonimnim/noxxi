import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

/// Service to handle location-based features
class LocationService {
  final ApiClient _apiClient = ApiClient.instance;
  static const String _selectedCityKey = 'noxxi_selected_city';
  static const String _recentCitiesKey = 'noxxi_recent_cities';
  
  /// Get available cities from events
  Future<List<String>> getAvailableCities() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.events,
        queryParameters: {
          'select': 'city',
          'filter[status]': 'published',
          'filter[date_after]': DateTime.now().toIso8601String(),
          'distinct': 'city',
        },
      );
      
      final cities = response
          .map((item) => item['city'] as String?)
          .where((city) => city != null && city.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      
      cities.sort();
      return cities;
    } catch (e) {
      debugPrint('Error fetching cities: $e');
      return [];
    }
  }
  
  /// Get popular cities with event counts
  Future<List<CityInfo>> getPopularCities({int limit = 10}) async {
    try {
      // This would ideally be a dedicated endpoint in Laravel
      final response = await _apiClient.get<List<dynamic>>(
        '/cities/popular',
        queryParameters: {'limit': limit},
      );
      
      return response.map((json) => CityInfo.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching popular cities: $e');
      // Fallback to getting available cities
      final cities = await getAvailableCities();
      return cities.take(limit).map((city) => CityInfo(
        name: city,
        eventCount: 0,
        imageUrl: null,
      )).toList();
    }
  }
  
  /// Get selected city from local storage
  Future<String?> getSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedCityKey);
    } catch (e) {
      debugPrint('Error getting selected city: $e');
      return null;
    }
  }
  
  /// Set selected city in local storage
  Future<void> setSelectedCity(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCityKey, city);
      
      // Add to recent cities
      await _addToRecentCities(city);
    } catch (e) {
      debugPrint('Error setting selected city: $e');
    }
  }
  
  /// Clear selected city
  Future<void> clearSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedCityKey);
    } catch (e) {
      debugPrint('Error clearing selected city: $e');
    }
  }
  
  /// Get recent cities from local storage
  Future<List<String>> getRecentCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentCitiesKey) ?? [];
    } catch (e) {
      debugPrint('Error getting recent cities: $e');
      return [];
    }
  }
  
  /// Add city to recent cities list
  Future<void> _addToRecentCities(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recentCities = prefs.getStringList(_recentCitiesKey) ?? [];
      
      // Remove if already exists
      recentCities.remove(city);
      
      // Add to beginning
      recentCities.insert(0, city);
      
      // Keep only last 10
      if (recentCities.length > 10) {
        recentCities = recentCities.take(10).toList();
      }
      
      await prefs.setStringList(_recentCitiesKey, recentCities);
    } catch (e) {
      debugPrint('Error adding to recent cities: $e');
    }
  }
  
  /// Get venues in a specific city
  Future<List<VenueInfo>> getVenuesInCity(String city) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.events,
        queryParameters: {
          'select': 'venue_name,venue_address,latitude,longitude',
          'filter[city]': city,
          'filter[status]': 'published',
          'distinct': 'venue_name',
        },
      );
      
      return response
          .where((item) => item['venue_name'] != null)
          .map((json) => VenueInfo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching venues: $e');
      return [];
    }
  }
}

/// City information model
class CityInfo {
  final String name;
  final int eventCount;
  final String? imageUrl;
  
  CityInfo({
    required this.name,
    required this.eventCount,
    this.imageUrl,
  });
  
  factory CityInfo.fromJson(Map<String, dynamic> json) {
    return CityInfo(
      name: json['name'] ?? '',
      eventCount: json['event_count'] ?? 0,
      imageUrl: json['image_url'],
    );
  }
}

/// Venue information model
class VenueInfo {
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  
  VenueInfo({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });
  
  factory VenueInfo.fromJson(Map<String, dynamic> json) {
    return VenueInfo(
      name: json['venue_name'] ?? '',
      address: json['venue_address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}