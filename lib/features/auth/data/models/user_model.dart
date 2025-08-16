import '../../domain/entities/user.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.phoneNumber,
    required super.role,
    required super.emailVerified,
    super.profileImageUrl,
    super.bio,
    super.location,
    super.country,
    super.preferredCurrency,
    required super.createdAt,
    required super.updatedAt,
    super.businessName,
    super.businessEmail,
    super.businessPhone,
    super.isApproved,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'],
      role: _parseRole(json['role'] ?? 'user'),
      emailVerified: json['email_verified'] ?? json['email_verified_at'] != null,
      profileImageUrl: json['profile_image_url'] ?? json['avatar_url'] ?? json['avatar'],
      bio: json['bio'],
      location: json['location'],
      country: json['country'],
      preferredCurrency: json['preferred_currency'] ?? 'KES',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      businessName: json['business_name'],
      businessEmail: json['business_email'],
      businessPhone: json['business_phone'],
      isApproved: json['is_approved'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role.value,
      'email_verified': emailVerified,
      'profile_image_url': profileImageUrl,
      'bio': bio,
      'location': location,
      'country': country,
      'preferred_currency': preferredCurrency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'business_name': businessName,
      'business_email': businessEmail,
      'business_phone': businessPhone,
      'is_approved': isApproved,
    };
  }

  static UserRole _parseRole(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.user,
    );
  }
}