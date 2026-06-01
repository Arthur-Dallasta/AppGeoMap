






import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

enum AuthStatus { authenticated, unauthenticated }


class AuthState {
  final AuthStatus status;
  final String? error; 

  const AuthState({required this.status, this.error});

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, String? error}) => AuthState(
        status: status ?? this.status,
        error: error,
      );
}



class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    
    final token = await SecureStorage.getToken();
    return AuthState(
      status: token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  
  Future<void> login(String email, String password) async {
    final token = await AuthRepository().login(email, password);
    await SecureStorage.saveToken(token);
    state = const AsyncData(AuthState(status: AuthStatus.authenticated));
  }

  Future<void> onLoginSuccess(String token) async {
    await SecureStorage.saveToken(token);
    state = const AsyncData(AuthState(status: AuthStatus.authenticated));
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
