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

  AuthDataModel({
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.user,
  });

  factory AuthDataModel.fromJson(Map<String, dynamic> json) {
    return AuthDataModel(
      accessToken: json['access_token'] ?? json['token'],
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: json['expires_in'],
      user: json['user'] != null 
          ? UserModel.fromJson(json['user'])
          : null,
    );
  }
}