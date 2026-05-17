// Контроллер аутентификации.
// На текущем этапе использует мок-OTP "000000" для офлайн-демо.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unauthenticated, codeSent, profilePending, authenticated }

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.phoneE164,
    this.displayName,
    this.username,
    this.errorCode,
  });

  final AuthStatus status;
  final String? phoneE164;
  final String? displayName;
  final String? username;
  final String? errorCode;

  AuthState copyWith({
    AuthStatus? status,
    String? phoneE164,
    String? displayName,
    String? username,
    String? errorCode,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneE164: phoneE164 ?? this.phoneE164,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  static const AuthState initial =
      AuthState(status: AuthStatus.unauthenticated);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState.initial);

  /// Мок-код для отладки UX без подключённого бэкенда.
  static const String mockOtp = '000000';

  Future<void> requestCode(String phoneE164) async {
    state = state.copyWith(clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      status: AuthStatus.codeSent,
      phoneE164: phoneE164,
      clearError: true,
    );
  }

  Future<bool> verifyCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (code.trim() == mockOtp) {
      state = state.copyWith(
        status: AuthStatus.profilePending,
        clearError: true,
      );
      return true;
    }
    state = state.copyWith(errorCode: 'INVALID_OTP');
    return false;
  }

  Future<void> completeProfile({
    required String displayName,
    required String username,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(
      status: AuthStatus.authenticated,
      displayName: displayName,
      username: username,
      clearError: true,
    );
  }

  Future<void> logout() async {
    state = AuthState.initial;
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (Ref ref) => AuthController(),
);
