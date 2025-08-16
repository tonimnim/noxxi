import 'user_model.dart';

class AuthResponseModel {
  final String status;
  final String? message;
  final AuthDataModel? data;
  final Map<String, dynamic>? errors;
  final String? code;

  AuthResponseModel({
    required this.status,
    this.message,
    this.data,
    this.errors,
    this.code,
  });

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      status: json['status'] ?? 'error',
      message: json['message'],
      data: json['data'] != null 
          ? AuthDataModel.fromJson(json['data'])
          : null,
      errors: json['errors'],
      code: json['code'],
    );
  }
}

class AuthDataModel {
  final String? accessToken;
  final String? tokenType;
  final int? expiresIn;
  final UserModel? user;
  // No refresh token as tokens never expire (100 years)
  final String? expiresAt;
  final String? refreshExpiresAt;

  AuthDataModel({
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.user,
    this.expiresAt,
    this.refreshExpiresAt,
  });

  factory AuthDataModel.fromJson(Map<String, dynamic> json) {
    return AuthDataModel(
      // Handle both 'token' and 'access_token' keys from Laravel
      accessToken: json['token'] ?? json['access_token'],
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'], // Kept for compatibility but ignored
      user: json['user'] != null 
          ? UserModel.fromJson(json['user'])
          : null,
      expiresAt: json['expires_at'], // 100 years from now
      refreshExpiresAt: json['refresh_expires_at'], // 100 years from now
    );
  }
}