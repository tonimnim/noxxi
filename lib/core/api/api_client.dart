import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';
import 'interceptors.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  
  // Singleton pattern
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }
  
  ApiClient._internal() {
    _storage = const FlutterSecureStorage();
    _dio = _createDio();
  }
  
  Dio get dio => _dio;
  FlutterSecureStorage get storage => _storage;
  
  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseApiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // Add interceptors in order
    dio.interceptors.addAll([
      AuthInterceptor(storage: _storage),
      LoggingInterceptor(), // Only in debug mode
      ErrorInterceptor(),
      RetryInterceptor(dio: dio),
    ]);
    
    return dio;
  }
  
  // Generic GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Generic DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Upload file
  Future<T> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileFieldName,
    Map<String, dynamic>? additionalData,
    T Function(dynamic)? fromJson,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData();
      
      // Add file
      formData.files.add(
        MapEntry(
          fileFieldName,
          await MultipartFile.fromFile(filePath),
        ),
      );
      
      // Add additional data
      if (additionalData != null) {
        formData.fields.addAll(
          additionalData.entries.map(
            (e) => MapEntry(e.key, e.value.toString()),
          ),
        );
      }
      
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Download file
  Future<void> downloadFile(
    String urlPath,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Handle response based on Laravel API structure
  T _handleResponse<T>(Response response, T Function(dynamic)? fromJson) {
    final data = response.data;
    
    // Check if response follows Laravel API structure
    if (data is Map && data.containsKey('status')) {
      if (data['status'] == 'success') {
        final responseData = data['data'];
        
        if (fromJson != null && responseData != null) {
          return fromJson(responseData);
        }
        
        return responseData as T;
      } else {
        throw ApiException(
          message: data['message'] ?? 'Request failed',
          statusCode: response.statusCode ?? 500,
          errorCode: data['code'] ?? 'API_ERROR',
        );
      }
    }
    
    // If response doesn't follow the structure, return as is
    if (fromJson != null) {
      return fromJson(data);
    }
    
    return data as T;
  }
  
  // Handle errors
  Exception _handleError(DioException error) {
    if (error.error is ApiException) {
      return error.error as ApiException;
    }
    
    return ApiException(
      message: error.message ?? 'An error occurred',
      statusCode: error.response?.statusCode ?? 0,
      errorCode: 'UNKNOWN_ERROR',
    );
  }
  
  // Save authentication data (tokens never expire now)
  Future<void> saveAuthData({
    required String token,
    Map<String, dynamic>? user,
  }) async {
    await _storage.write(key: 'access_token', value: token);
    
    // No longer storing refresh token as tokens never expire
    
    if (user != null) {
      await _storage.write(key: 'user', value: user.toString());
    }
  }
  
  // Clear authentication data
  Future<void> clearAuthData() async {
    await _storage.deleteAll();
  }
  
  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}