// Контроллер аутентификации NOCTIS — регистрация без телефона.
// Достаточно имени, никнейма и (опционально) аватарки.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unauthenticated, authenticated }

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.displayName,
    this.username,
    this.avatarPath,
    this.bio,
  });

  final AuthStatus status;
  final String? displayName;
  final String? username;

  /// Локальный путь к файлу с аватаркой (image_picker сохраняет его в кэш).
  final String? avatarPath;
  final String? bio;

  AuthState copyWith({
    AuthStatus? status,
    String? displayName,
    String? username,
    String? avatarPath,
    String? bio,
    bool clearAvatar = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      bio: bio ?? this.bio,
    );
  }

  static const AuthState initial =
      AuthState(status: AuthStatus.unauthenticated);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState.initial) {
    _restore();
  }

  static const String _kName = 'noctis.auth.name';
  static const String _kUsername = 'noctis.auth.username';
  static const String _kAvatar = 'noctis.auth.avatar';
  static const String _kBio = 'noctis.auth.bio';

  Future<void> _restore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString(_kName);
      final String? username = prefs.getString(_kUsername);
      if (name != null && username != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          displayName: name,
          username: username,
          avatarPath: prefs.getString(_kAvatar),
          bio: prefs.getString(_kBio),
        );
      }
    } catch (_) {
      // Игнорируем ошибки persistence — фолбэк на анонимный старт.
    }
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kName, state.displayName ?? '');
      await prefs.setString(_kUsername, state.username ?? '');
      if (state.avatarPath != null) {
        await prefs.setString(_kAvatar, state.avatarPath!);
      } else {
        await prefs.remove(_kAvatar);
      }
      if (state.bio != null) {
        await prefs.setString(_kBio, state.bio!);
      } else {
        await prefs.remove(_kBio);
      }
    } catch (_) {}
  }

  Future<void> register({
    required String displayName,
    required String username,
    String? avatarPath,
  }) async {
    state = AuthState(
      status: AuthStatus.authenticated,
      displayName: displayName,
      username: username,
      avatarPath: avatarPath,
    );
    await _persist();
  }

  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? avatarPath,
    String? bio,
    bool clearAvatar = false,
  }) async {
    state = state.copyWith(
      displayName: displayName,
      username: username,
      avatarPath: avatarPath,
      bio: bio,
      clearAvatar: clearAvatar,
    );
    await _persist();
  }

  Future<void> logout() async {
    state = AuthState.initial;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kName);
      await prefs.remove(_kUsername);
      await prefs.remove(_kAvatar);
      await prefs.remove(_kBio);
    } catch (_) {}
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (Ref ref) => AuthController(),
);
