// Состояние раздела «Безопасность».
// Локальное хранилище в памяти; синхронизация с бэкендом будет добавлена позже.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.device,
    required this.os,
    required this.location,
    required this.lastSeen,
    required this.current,
  });

  final String id;
  final String device;
  final String os;
  final String location;
  final DateTime lastSeen;
  final bool current;
}

@immutable
class PrivacyVisibility {
  const PrivacyVisibility({
    required this.lastSeen,
    required this.profilePhoto,
    required this.calls,
    required this.forwards,
  });

  final String lastSeen;
  final String profilePhoto;
  final String calls;
  final String forwards;

  PrivacyVisibility copyWith({
    String? lastSeen,
    String? profilePhoto,
    String? calls,
    String? forwards,
  }) {
    return PrivacyVisibility(
      lastSeen: lastSeen ?? this.lastSeen,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      calls: calls ?? this.calls,
      forwards: forwards ?? this.forwards,
    );
  }

  static const PrivacyVisibility defaults = PrivacyVisibility(
    lastSeen: 'Контакты',
    profilePhoto: 'Все',
    calls: 'Контакты',
    forwards: 'Все',
  );
}

@immutable
class SecurityState {
  const SecurityState({
    required this.appLock,
    required this.biometric,
    required this.hidePreview,
    required this.cloudPasswordSet,
    required this.privacy,
    required this.sessions,
  });

  final bool appLock;
  final bool biometric;
  final bool hidePreview;
  final bool cloudPasswordSet;
  final PrivacyVisibility privacy;
  final List<SessionInfo> sessions;

  SecurityState copyWith({
    bool? appLock,
    bool? biometric,
    bool? hidePreview,
    bool? cloudPasswordSet,
    PrivacyVisibility? privacy,
    List<SessionInfo>? sessions,
  }) {
    return SecurityState(
      appLock: appLock ?? this.appLock,
      biometric: biometric ?? this.biometric,
      hidePreview: hidePreview ?? this.hidePreview,
      cloudPasswordSet: cloudPasswordSet ?? this.cloudPasswordSet,
      privacy: privacy ?? this.privacy,
      sessions: sessions ?? this.sessions,
    );
  }
}

class SecurityController extends StateNotifier<SecurityState> {
  SecurityController()
      : super(SecurityState(
          appLock: false,
          biometric: false,
          hidePreview: false,
          cloudPasswordSet: false,
          privacy: PrivacyVisibility.defaults,
          sessions: <SessionInfo>[
            SessionInfo(
              id: 'this',
              device: 'Текущее устройство',
              os: 'Android',
              location: 'Россия',
              lastSeen: DateTime.now(),
              current: true,
            ),
            SessionInfo(
              id: 'web',
              device: 'NOCTIS Web',
              os: 'Chrome · macOS',
              location: 'Москва',
              lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
              current: false,
            ),
          ],
        ));

  void setAppLock(bool v) {
    state = state.copyWith(
      appLock: v,
      biometric: v ? state.biometric : false,
    );
  }

  void setBiometric(bool v) {
    if (!state.appLock) return;
    state = state.copyWith(biometric: v);
  }

  void setHidePreview(bool v) => state = state.copyWith(hidePreview: v);
  void setCloudPassword(bool v) =>
      state = state.copyWith(cloudPasswordSet: v);
  void setPrivacy(PrivacyVisibility p) => state = state.copyWith(privacy: p);

  void revokeSession(String id) {
    state = state.copyWith(
      sessions: state.sessions.where((SessionInfo s) => s.id != id).toList(),
    );
  }

  void revokeAllOthers() {
    state = state.copyWith(
      sessions: state.sessions.where((SessionInfo s) => s.current).toList(),
    );
  }
}

final StateNotifierProvider<SecurityController, SecurityState>
    securityProvider =
    StateNotifierProvider<SecurityController, SecurityState>(
  (Ref ref) => SecurityController(),
);
