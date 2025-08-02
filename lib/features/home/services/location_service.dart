import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle location-based features
class LocationService {
  final _supabase = Supabase.instance.client;
  static const String _selectedCityKey = 'noxxi_selected_city';
  static const String _recentCitiesKey = 'noxxi_recent_cities';
  
  /// Get available cities from events
  Future<List<String>> getAvailableCities() async {
    try {
      final response = await _supabase
          .from('events')
          .select('city')
          .eq('status', 'published')
          .gte('event_date', DateTime.now().toIso8601String())
          .not('city', 'is', null);
      
      final cities = (response as List)
          .map((item) => item['city'] as String)
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      
      return cities;
    } catch (e) {
      debugPrint('Error fetching cities: $e');
      return _getDefaultCities();
    }
  }
  
  /// Get popular cities based on event count
  Future<List<CityInfo>> getPopularCities({int limit = 10}) async {
    try {
      final response = await _supabase.rpc('get_popular_cities', params: {
        'limit_count': limit,
      });
      
      return (response as List)
          .map((json) => CityInfo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching popular cities: $e');
      // Fallback to default cities
      return _getDefaultCities()
          .map((city) => CityInfo(name: city, eventCount: 0))
          .toList();
    }
  }
  
  /// Get user's selected city
  Future<String?> getSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedCityKey);
    } catch (e) {
      debugPrint('Error getting selected city: $e');
      return null;
    }
  }
  
  /// Set user's selected city
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
  
  /// Get user's recent cities
  Future<List<String>> getRecentCities({int limit = 5}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentCities = prefs.getStringList(_recentCitiesKey) ?? [];
      return recentCities.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent cities: $e');
      return [];
    }
  }
  
  /// Add city to recent cities list
  Future<void> _addToRecentCities(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentCities = prefs.getStringList(_recentCitiesKey) ?? [];
      
      // Remove if already exists and add to front
      recentCities.remove(city);
      recentCities.insert(0, city);
      
      // Keep only last 10 cities
      if (recentCities.length > 10) {
        recentCities.removeRange(10, recentCities.length);
      }
      
      await prefs.setStringList(_recentCitiesKey, recentCities);
    } catch (e) {
      debugPrint('Error adding to recent cities: $e');
    }
  }
  
  /// Get venues for a specific city
  Future<List<VenueInfo>> getVenuesInCity(String city) async {
    try {
      final response = await _supabase
          .from('events')
          .select('venue_name, venue_address, latitude, longitude')
          .eq('city', city)
          .eq('status', 'published')
          .gte('event_date', DateTime.now().toIso8601String())
          .not('venue_name', 'is', null);
      
      final venuesMap = <String, VenueInfo>{};
      
      for (final item in response as List) {
        final venueName = item['venue_name'] as String;
        if (!venuesMap.containsKey(venueName)) {
          venuesMap[venueName] = VenueInfo(
            name: venueName,
            address: item['venue_address'],
            city: city,
            latitude: item['latitude']?.toDouble(),
            longitude: item['longitude']?.toDouble(),
            eventCount: 1,
          );
        } else {
          venuesMap[venueName]!.eventCount++;
        }
      }
      
      final venues = venuesMap.values.toList()
        ..sort((a, b) => b.eventCount.compareTo(a.eventCount));
      
      return venues;
    } catch (e) {
      debugPrint('Error fetching venues: $e');
      return [];
    }
  }
  
  /// Get default cities for Kenya
  List<String> _getDefaultCities() {
    return [
      'Nairobi',
      'Mombasa',
      'Kisumu',
      'Nakuru',
      'Eldoret',
      'Thika',
      'Nyeri',
      'Machakos',
      'Meru',
      'Kakamega',
    ];
  }
  
  /// Clear location preferences
  Future<void> clearLocationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedCityKey);
      await prefs.remove(_recentCitiesKey);
    } catch (e) {
      debugPrint('Error clearing location preferences: $e');
    }
  }
}

/// City information model
class CityInfo {
  final String name;
  int eventCount;
  final double? latitude;
  final double? longitude;
  
  CityInfo({
    required this.name,
    required this.eventCount,
    this.latitude,
    this.longitude,
  });
  
  factory CityInfo.fromJson(Map<String, dynamic> json) {
    return CityInfo(
      name: json['city'] ?? json['name'],
      eventCount: json['event_count'] ?? 0,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}

/// Venue information model
class VenueInfo {
  final String name;
  final String? address;
  final String city;
  final double? latitude;
  final double? longitude;
  int eventCount;
  
  VenueInfo({
    required this.name,
    this.address,
    required this.city,
    this.latitude,
    this.longitude,
    this.eventCount = 0,
  });
  
  String get fullAddress {
    if (address != null && address!.isNotEmpty) {
      return '$address, $city';
    }
    return city;
  }
}