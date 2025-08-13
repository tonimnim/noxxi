import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

// Auth Interceptor - Adds authorization token to requests
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  
  AuthInterceptor({required this.storage});
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add auth token if available
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add common headers
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    
    developer.log(
      'REQUEST[${options.method}] => PATH: ${options.path}',
      name: 'API',
    );
    
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      name: 'API',
    );
    
    super.onResponse(response, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    developer.log(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      name: 'API',
      error: err.message,
    );
    
    // Handle 401 Unauthorized - Token expired
    if (err.response?.statusCode == 401) {
      // Clear stored credentials
      await storage.deleteAll();
      
      // TODO: Navigate to login screen
      // Get.offAllNamed('/login'); // If using GetX
    }
    
    super.onError(err, handler);
  }
}

// Logging Interceptor - For debugging
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      'Request: ${options.method} ${options.uri}',
      name: 'HTTP',
    );
    
    if (options.data != null) {
      developer.log(
        'Request Data: ${options.data}',
        name: 'HTTP',
      );
    }
    
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      'Response [${response.statusCode}]: ${response.data}',
      name: 'HTTP',
    );
    
    super.onResponse(response, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      'Error: ${err.message}',
      name: 'HTTP',
      error: err.response?.data,
    );
    
    super.onError(err, handler);
  }
}

// Error Interceptor - Standardizes error handling
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException apiException;
    
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        apiException = ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 408,
          errorCode: 'TIMEOUT',
        );
        break;
        
      case DioExceptionType.connectionError:
        apiException = ApiException(
          message: 'No internet connection. Please check your network.',
          statusCode: 0,
          errorCode: 'NO_CONNECTION',
        );
        break;
        
      case DioExceptionType.badResponse:
        final response = err.response;
        String message = 'An error occurred';
        String errorCode = 'UNKNOWN_ERROR';
        
        // Parse Laravel error response
        if (response?.data != null) {
          if (response!.data is Map) {
            message = response.data['message'] ?? 
                     response.data['error'] ?? 
                     message;
            errorCode = response.data['code'] ?? errorCode;
            
            // Handle validation errors
            if (response.data['errors'] != null) {
              final errors = response.data['errors'] as Map;
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                message = firstError.first;
              }
            }
          } else {
            message = response.data.toString();
          }
        }
        
        apiException = ApiException(
          message: message,
          statusCode: response?.statusCode ?? 500,
          errorCode: errorCode,
          validationErrors: response?.data?['errors'],
        );
        break;
        
      case DioExceptionType.cancel:
        apiException = ApiException(
          message: 'Request cancelled',
          statusCode: 0,
          errorCode: 'CANCELLED',
        );
        break;
        
      default:
        apiException = ApiException(
          message: err.message ?? 'An unexpected error occurred',
          statusCode: 500,
          errorCode: 'UNKNOWN',
        );
    }
    
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
      ),
    );
  }
}

// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String errorCode;
  final Map<String, dynamic>? validationErrors;
  
  ApiException({
    required this.message,
    required this.statusCode,
    required this.errorCode,
    this.validationErrors,
  });
  
  @override
  String toString() => message;
  
  bool get isNetworkError => statusCode == 0;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
}

// Retry Interceptor - Retries failed requests
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
  });
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    
    // Only retry on network errors and if we haven't exceeded max retries
    if (retryCount < maxRetries && 
        (err.type == DioExceptionType.connectionTimeout ||
         err.type == DioExceptionType.connectionError ||
         err.type == DioExceptionType.receiveTimeout)) {
      
      developer.log(
        'Retrying request (${retryCount + 1}/$maxRetries): ${err.requestOptions.path}',
        name: 'API',
      );
      
      // Exponential backoff
      await Future.delayed(Duration(seconds: retryCount + 1));
      
      // Update retry count
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}