// Сервис звуков NOCTIS.
// Использует системные SystemSound + вибрацию для гудков звонка
// и тактильный отклик при отправке/получении сообщений.
//
// Звуки отключаются через NotificationsController (см. notifications_state.dart).
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class SoundService {
  SoundService._();

  static bool _soundsEnabled = true;
  static bool _vibrationEnabled = true;

  static Timer? _ringTimer;

  static void setSoundsEnabled(bool v) => _soundsEnabled = v;
  static void setVibrationEnabled(bool v) => _vibrationEnabled = v;
  static bool get soundsEnabled => _soundsEnabled;
  static bool get vibrationEnabled => _vibrationEnabled;

  /// Тонкий «дзинь» при отправке сообщения.
  static Future<void> messageSent() async {
    if (!_soundsEnabled) return;
    await SystemSound.play(SystemSoundType.click);
  }

  /// Лёгкий звук + одиночный паттерн вибро при входящем сообщении.
  static Future<void> messageReceived() async {
    if (_soundsEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (_vibrationEnabled) {
      try {
        if ((await Vibration.hasVibrator()) ?? false) {
          await Vibration.vibrate(duration: 80);
        }
      } catch (_) {}
    }
  }

  /// Старт «гудков» входящего вызова: повтор паттерна вибро каждые 2 с
  /// + системный alert sound. Выключается через [stopRingtone].
  static Future<void> startRingtone() async {
    await stopRingtone();
    bool hasVibe = false;
    try {
      hasVibe = (await Vibration.hasVibrator()) ?? false;
    } catch (_) {}
    _ringTimer = Timer.periodic(const Duration(seconds: 2), (Timer _) async {
      if (_soundsEnabled) {
        SystemSound.play(SystemSoundType.alert);
      }
      if (_vibrationEnabled && hasVibe) {
        try {
          await Vibration.vibrate(
            pattern: <int>[0, 400, 200, 400, 200, 400],
            intensities: <int>[0, 200, 0, 200, 0, 200],
          );
        } catch (_) {}
      }
    });
  }

  static Future<void> stopRingtone() async {
    _ringTimer?.cancel();
    _ringTimer = null;
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  /// Отдельный паттерн «гудки исходящего вызова».
  static Timer? _dialTimer;
  static Future<void> startDialTone() async {
    await stopDialTone();
    _dialTimer = Timer.periodic(const Duration(milliseconds: 1500),
        (Timer _) async {
      if (_soundsEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
    });
  }

  static Future<void> stopDialTone() async {
    _dialTimer?.cancel();
    _dialTimer = null;
  }
}
