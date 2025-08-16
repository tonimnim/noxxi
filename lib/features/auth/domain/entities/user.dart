import 'package:equatable/equatable.dart';

enum UserRole {
  user,
  attendee, 
  organizer,
  manager,
  admin;
  
  String get value => name;
}

class UserEntity extends Equatable {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final UserRole role;
  final bool emailVerified;
  final String? profileImageUrl;
  final String? bio;
  final String? location;
  final String? country; // Added field
  final String? preferredCurrency; // Added field
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Organizer specific fields (if user is organizer)
  final String? businessName;
  final String? businessEmail;
  final String? businessPhone;
  final bool? isApproved;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.emailVerified,
    this.profileImageUrl,
    this.bio,
    this.location,
    this.country,
    this.preferredCurrency,
    required this.createdAt,
    required this.updatedAt,
    this.businessName,
    this.businessEmail,
    this.businessPhone,
    this.isApproved,
  });
  
  bool get isOrganizer => role == UserRole.organizer;
  bool get isAttendee => role == UserRole.attendee || role == UserRole.user;
  bool get isManager => role == UserRole.manager;
  bool get isAdmin => role == UserRole.admin;
  bool get isApprovedOrganizer => isOrganizer && (isApproved ?? false);
  
  @override
  List<Object?> get props => [
    id, 
    fullName, 
    email, 
    phoneNumber, 
    role, 
    emailVerified,
    profileImageUrl,
    bio,
    location,
    country,
    preferredCurrency,
    createdAt,
    updatedAt,
    businessName,
    businessEmail,
    businessPhone,
    isApproved,
  ];
}