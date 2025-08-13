import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/interceptors.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(LoginParams params);
  Future<UserModel> register(RegisterParams params);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<void> requestPasswordReset(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login(LoginParams params) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {
          'email': params.email,
          'password': params.password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response);
      
      if (authResponse.isSuccess && authResponse.data?.user != null) {
        // Save token
        if (authResponse.data?.accessToken != null) {
          await apiClient.saveAuthData(
            token: authResponse.data!.accessToken!,
            user: authResponse.data!.user!.toJson(),
          );
        }
        return authResponse.data!.user!;
      }
      
      throw ApiException(
        message: authResponse.message ?? 'Login failed',
        statusCode: 401,
        errorCode: authResponse.code ?? 'LOGIN_FAILED',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  @override
  Future<UserModel> register(RegisterParams params) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'full_name': params.fullName,
          'email': params.email,
          'password': params.password,
          'password_confirmation': params.passwordConfirmation,
          'phone_number': params.phoneNumber,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response);
      
      if (authResponse.isSuccess && authResponse.data?.user != null) {
        // Save token if provided (auto-login after registration)
        if (authResponse.data?.accessToken != null) {
          await apiClient.saveAuthData(
            token: authResponse.data!.accessToken!,
            user: authResponse.data!.user!.toJson(),
          );
        }
        return authResponse.data!.user!;
      }
      
      throw ApiException(
        message: authResponse.message ?? 'Registration failed',
        statusCode: 422,
        errorCode: authResponse.code ?? 'REGISTRATION_FAILED',
        validationErrors: authResponse.errors,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      // Continue with local logout even if API fails
    } finally {
      await apiClient.clearAuthData();
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.currentUser,
      );

      final authResponse = AuthResponseModel.fromJson(response);
      
      if (authResponse.isSuccess && authResponse.data?.user != null) {
        return authResponse.data!.user!;
      }
      
      throw ApiException(
        message: 'Failed to get user data',
        statusCode: 401,
        errorCode: 'USER_NOT_FOUND',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.requestPasswordReset,
        data: {'email': email},
      );

      final authResponse = AuthResponseModel.fromJson(response);
      
      if (!authResponse.isSuccess) {
        throw ApiException(
          message: authResponse.message ?? 'Failed to send reset email',
          statusCode: 400,
          errorCode: authResponse.code ?? 'RESET_FAILED',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: e.toString(),
        statusCode: 0,
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }
}