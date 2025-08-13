import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import 'login_usecase.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}