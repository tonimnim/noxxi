import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;
  
  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  String? _errorMessage;
  
  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  AuthProvider({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.authRepository,
  }) {
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    
    final result = await authRepository.getCurrentUser();
    
    result.fold(
      (failure) => _setStatus(AuthStatus.unauthenticated),
      (user) {
        _user = user;
        _setStatus(AuthStatus.authenticated);
      },
    );
  }
  
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    _clearError();
    
    final params = LoginParams(email: email, password: password);
    final result = await loginUseCase(params);
    
    return result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(AuthStatus.unauthenticated);
        return false;
      },
      (user) {
        _user = user;
        _setStatus(AuthStatus.authenticated);
        return true;
      },
    );
  }
  
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phoneNumber,
  }) async {
    _setStatus(AuthStatus.loading);
    _clearError();
    
    final params = RegisterParams(
      fullName: fullName,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      phoneNumber: phoneNumber,
    );
    
    final result = await registerUseCase(params);
    
    return result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(AuthStatus.unauthenticated);
        return false;
      },
      (user) {
        _user = user;
        _setStatus(AuthStatus.authenticated);
        return true;
      },
    );
  }
  
  Future<void> logout() async {
    _setStatus(AuthStatus.loading);
    
    await logoutUseCase();
    
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }
  
  Future<bool> requestPasswordReset(String email) async {
    _clearError();
    
    final result = await authRepository.requestPasswordReset(email);
    
    return result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (_) => true,
    );
  }
  
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}