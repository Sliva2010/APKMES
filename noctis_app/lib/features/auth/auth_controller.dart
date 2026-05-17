// Контроллер аутентификации.
//
// Если `--dart-define=BACKEND_URL=...` задан — выполняет реальные REST-запросы
// к NOCTIS-бэкенду. В демо-режиме (URL пуст) принимает код `000000`.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/auth_api.dart';
import '../../core/network/backend_config.dart';

enum AuthStatus { unauthenticated, codeSent, profilePending, authenticated }

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.phoneE164,
    this.displayName,
    this.username,
    this.errorCode,
    this.access,
    this.refresh,
    this.userId,
  });

  final AuthStatus status;
  final String? phoneE164;
  final String? displayName;
  final String? username;
  final String? errorCode;
  final String? access;
  final String? refresh;
  final int? userId;

  AuthState copyWith({
    AuthStatus? status,
    String? phoneE164,
    String? displayName,
    String? username,
    String? errorCode,
    String? access,
    String? refresh,
    int? userId,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneE164: phoneE164 ?? this.phoneE164,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      access: access ?? this.access,
      refresh: refresh ?? this.refresh,
      userId: userId ?? this.userId,
    );
  }

  static const AuthState initial =
      AuthState(status: AuthStatus.unauthenticated);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState.initial);

  static const String mockOtp = '000000';
  final AuthApi _api = AuthApi();

  Future<void> requestCode(String phoneE164) async {
    state = state.copyWith(clearError: true);
    if (BackendConfig.isConfigured) {
      try {
        await _api.startPhone(phoneE164);
      } catch (_) {
        // Сетевая ошибка не блокирует UX — пользователь всё равно перейдёт
        // на экран кода. Реальный backend отдаст ошибку при verify.
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    state = state.copyWith(
      status: AuthStatus.codeSent,
      phoneE164: phoneE164,
      clearError: true,
    );
  }

  Future<bool> verifyCode(String code) async {
    final String phone = state.phoneE164 ?? '';
    if (BackendConfig.isConfigured) {
      try {
        final TokenPair pair = await _api.verifyPhone(phone, code.trim());
        state = state.copyWith(
          status: AuthStatus.profilePending,
          access: pair.access,
          refresh: pair.refresh,
          userId: pair.userId,
          clearError: true,
        );
        return true;
      } catch (_) {
        state = state.copyWith(errorCode: 'INVALID_OTP');
        return false;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
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

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (Ref ref) => AuthController(),
);
