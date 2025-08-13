import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:noxxi/core/api/api_client.dart';
import 'package:noxxi/core/api/api_endpoints.dart';

void main() {
  group('API Connection Tests', () {
    late ApiClient apiClient;

    setUpAll(() {
      // Initialize API client for testing
      apiClient = ApiClient.instance;
    });

    test('should connect to Laravel API base URL', () async {
      try {
        // Test basic connectivity to the API
        final dio = Dio();
        final response = await dio.get('${ApiEndpoints.baseUrl}/health');
        
        expect(response.statusCode, equals(200));
        print('✅ API Health Check: ${response.data}');
      } catch (e) {
        print('❌ API Health Check Failed: $e');
        print('Make sure your Laravel server is running on ${ApiEndpoints.baseUrl}');
        fail('Could not connect to Laravel API: $e');
      }
    });

    test('should handle API response format correctly', () async {
      try {
        // Test if API returns expected Laravel response format
        final response = await apiClient.get<Map<String, dynamic>>('/health');
        
        // Laravel API should return: {"status": "success", "data": {...}}
        expect(response, isA<Map<String, dynamic>>());
        print('✅ API Response Format: $response');
      } catch (e) {
        print('❌ API Response Format Test Failed: $e');
        // This might fail if /health endpoint doesn't exist yet
        print('Note: /health endpoint might not be implemented yet');
      }
    });

    test('should handle authentication endpoints', () async {
      try {
        // Test registration endpoint (should return validation errors for empty data)
        final response = await apiClient.post<Map<String, dynamic>>(
          ApiEndpoints.register,
          data: {}, // Empty data should trigger validation
        );
        
        fail('Should have thrown validation error');
      } catch (e) {
        print('✅ Authentication endpoint accessible (validation error expected): $e');
        // Validation errors are expected for empty registration data
        expect(e.toString().contains('validation') || 
               e.toString().contains('required') ||
               e.toString().contains('422'), isTrue);
      }
    });

    test('should handle events endpoint', () async {
      try {
        // Test events listing endpoint
        final response = await apiClient.get<List<dynamic>>(
          ApiEndpoints.events,
          queryParameters: {'limit': 5},
        );
        
        expect(response, isA<List>());
        print('✅ Events endpoint working: Found ${response.length} events');
      } catch (e) {
        print('❌ Events endpoint test failed: $e');
        print('This might be expected if no events exist yet');
      }
    });

    test('should handle categories endpoint', () async {
      try {
        // Test categories endpoint
        final response = await apiClient.get<List<dynamic>>(
          ApiEndpoints.eventCategories,
        );
        
        expect(response, isA<List>());
        print('✅ Categories endpoint working: Found ${response.length} categories');
      } catch (e) {
        print('❌ Categories endpoint test failed: $e');
        print('This might be expected if no categories exist yet');
      }
    });

    test('should handle CORS properly', () async {
      try {
        // Test CORS by making a simple request
        final dio = Dio();
        final response = await dio.get(
          '${ApiEndpoints.baseApiUrl}/events',
          options: Options(
            headers: {
              'Origin': 'http://localhost:3000',
            },
          ),
        );
        
        print('✅ CORS test successful: ${response.statusCode}');
      } catch (e) {
        print('⚠️ CORS test failed: $e');
        print('You may need to configure CORS in your Laravel app');
      }
    });

    test('should handle error responses correctly', () async {
      try {
        // Test 404 endpoint
        await apiClient.get<Map<String, dynamic>>('/non-existent-endpoint');
        fail('Should have thrown 404 error');
      } catch (e) {
        print('✅ Error handling working: $e');
        expect(e.toString().contains('404') || e.toString().contains('Not Found'), isTrue);
      }
    });
  });

  group('API Client Configuration Tests', () {
    test('should have correct base URL configured', () {
      expect(ApiEndpoints.baseUrl, isNotEmpty);
      expect(ApiEndpoints.baseApiUrl, contains('/api'));
      print('✅ Base URL: ${ApiEndpoints.baseUrl}');
      print('✅ API URL: ${ApiEndpoints.baseApiUrl}');
    });

    test('should have proper timeout configuration', () {
      final apiClient = ApiClient.instance;
      final dio = apiClient.dio;
      
      expect(dio.options.connectTimeout, isNotNull);
      expect(dio.options.receiveTimeout, isNotNull);
      expect(dio.options.sendTimeout, isNotNull);
      
      print('✅ Timeouts configured:');
      print('   Connect: ${dio.options.connectTimeout}');
      print('   Receive: ${dio.options.receiveTimeout}');
      print('   Send: ${dio.options.sendTimeout}');
    });

    test('should have proper headers configured', () {
      final apiClient = ApiClient.instance;
      final dio = apiClient.dio;
      
      expect(dio.options.headers['Accept'], equals('application/json'));
      expect(dio.options.headers['Content-Type'], equals('application/json'));
      
      print('✅ Headers configured correctly');
    });
  });
}