import 'package:dartz/dartz.dart';
import '../../../../core/api/interceptors.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> login(LoginParams params) async {
    try {
      final user = await remoteDataSource.login(params);
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return const Left(InvalidCredentialsFailure());
      } else if (e.isNetworkError) {
        return const Left(NetworkFailure());
      } else if (e.isValidationError) {
        return Left(ValidationFailure(e.message, errors: e.validationErrors));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(RegisterParams params) async {
    try {
      final user = await remoteDataSource.register(params);
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        return const Left(NetworkFailure());
      } else if (e.isValidationError) {
        return Left(ValidationFailure(e.message, errors: e.validationErrors));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      // Even if remote logout fails, clear local data
      await localDataSource.clearCache();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      // Try to get from cache first
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        // Verify with remote if possible
        try {
          final remoteUser = await remoteDataSource.getCurrentUser();
          await localDataSource.cacheUser(remoteUser);
          return Right(remoteUser);
        } catch (e) {
          // Return cached user if remote fails
          return Right(cachedUser);
        }
      }
      
      // No cached user, get from remote
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        return const Left(UnauthorizedFailure());
      } else if (e.isNetworkError) {
        // Try to return cached user on network error
        final cachedUser = await localDataSource.getCachedUser();
        if (cachedUser != null) {
          return Right(cachedUser);
        }
        return const Left(NetworkFailure());
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final isLoggedIn = await localDataSource.isLoggedIn();
      return Right(isLoggedIn);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset(String email) async {
    try {
      await remoteDataSource.requestPasswordReset(email);
      return const Right(null);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        return const Left(NetworkFailure());
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}