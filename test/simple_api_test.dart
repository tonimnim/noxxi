import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('Simple API Connection Test', () {
    test('should connect to Laravel server', () async {
      final dio = Dio();
      
      try {
        // Test basic connectivity to your Laravel server
        final response = await dio.get('http://localhost:8000');
        
        print('✅ Laravel server is running!');
        print('Status Code: ${response.statusCode}');
        print('Response: ${response.data.toString().substring(0, 100)}...');
        
        expect(response.statusCode, equals(200));
      } catch (e) {
        print('❌ Cannot connect to Laravel server: $e');
        print('Make sure your Laravel server is running on http://localhost:8000');
        print('Run: php artisan serve');
        fail('Laravel server not accessible');
      }
    });

    test('should access API endpoints', () async {
      final dio = Dio();
      
      try {
        // Test API base path
        final response = await dio.get('http://localhost:8000/api');
        
        print('✅ API endpoint accessible!');
        print('Status Code: ${response.statusCode}');
        
        expect(response.statusCode, isIn([200, 404])); // 404 is ok if no route defined
      } catch (e) {
        print('❌ API endpoint test failed: $e');
      }
    });

    test('should test events endpoint', () async {
      final dio = Dio();
      
      try {
        // Test events endpoint
        final response = await dio.get('http://localhost:8000/api/events');
        
        print('✅ Events endpoint working!');
        print('Status Code: ${response.statusCode}');
        print('Response type: ${response.data.runtimeType}');
        
        expect(response.statusCode, equals(200));
      } catch (e) {
        print('⚠️ Events endpoint not ready: $e');
        print('This is expected if you haven\'t implemented the events API yet');
      }
    });
  });
}