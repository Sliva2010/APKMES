// Состояние настроек уведомлений и звуков.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/audio/sound_service.dart';

@immutable
class NotificationsState {
  const NotificationsState({
    required this.messageSounds,
    required this.callRingtone,
    required this.vibration,
    required this.preview,
    required this.systemNotifications,
  });

  final bool messageSounds;
  final bool callRingtone;
  final bool vibration;
  final bool preview;
  final bool systemNotifications;

  NotificationsState copyWith({
    bool? messageSounds,
    bool? callRingtone,
    bool? vibration,
    bool? preview,
    bool? systemNotifications,
  }) {
    return NotificationsState(
      messageSounds: messageSounds ?? this.messageSounds,
      callRingtone: callRingtone ?? this.callRingtone,
      vibration: vibration ?? this.vibration,
      preview: preview ?? this.preview,
      systemNotifications: systemNotifications ?? this.systemNotifications,
    );
  }

  static const NotificationsState defaults = NotificationsState(
    messageSounds: true,
    callRingtone: true,
    vibration: true,
    preview: true,
    systemNotifications: true,
  );
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController() : super(NotificationsState.defaults) {
    _restore();
  }

  static const String _kMs = 'noctis.notif.ms';
  static const String _kCall = 'noctis.notif.call';
  static const String _kVib = 'noctis.notif.vib';
  static const String _kPrev = 'noctis.notif.prev';
  static const String _kSys = 'noctis.notif.sys';

  Future<void> _restore() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      state = NotificationsState(
        messageSounds: p.getBool(_kMs) ?? true,
        callRingtone: p.getBool(_kCall) ?? true,
        vibration: p.getBool(_kVib) ?? true,
        preview: p.getBool(_kPrev) ?? true,
        systemNotifications: p.getBool(_kSys) ?? true,
      );
      SoundService.setSoundsEnabled(state.messageSounds);
      SoundService.setVibrationEnabled(state.vibration);
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_kMs, state.messageSounds);
      await p.setBool(_kCall, state.callRingtone);
      await p.setBool(_kVib, state.vibration);
      await p.setBool(_kPrev, state.preview);
      await p.setBool(_kSys, state.systemNotifications);
    } catch (_) {}
  }

  void setMessageSounds(bool v) {
    state = state.copyWith(messageSounds: v);
    SoundService.setSoundsEnabled(v);
    _persist();
  }

  void setCallRingtone(bool v) {
    state = state.copyWith(callRingtone: v);
    _persist();
  }

  void setVibration(bool v) {
    state = state.copyWith(vibration: v);
    SoundService.setVibrationEnabled(v);
    _persist();
  }

  void setPreview(bool v) {
    state = state.copyWith(preview: v);
    _persist();
  }

  void setSystemNotifications(bool v) {
    state = state.copyWith(systemNotifications: v);
    _persist();
  }
}

final StateNotifierProvider<NotificationsController, NotificationsState>
    notificationsProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>(
  (Ref ref) => NotificationsController(),
);
