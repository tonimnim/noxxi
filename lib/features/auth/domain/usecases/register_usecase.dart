import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import 'login_usecase.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    return await repository.register(params);
  }
}

class RegisterParams extends Equatable {
  final String fullName;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phoneNumber;
  final String? country;
  final String? preferredCurrency;

  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phoneNumber,
    this.country,
    this.preferredCurrency,
  });

  @override
  List<Object?> get props => [
    fullName,
    email,
    password,
    passwordConfirmation,
    phoneNumber,
    country,
    preferredCurrency,
  ];
}