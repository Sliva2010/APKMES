// Сервис тактильной обратной связи.
// Безопасно деградирует на устройствах без вибромотора.
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticsService {
  HapticsService._();

  static bool? _hasVibrator;

  static Future<bool> _ensureSupport() async {
    _hasVibrator ??= (await Vibration.hasVibrator()) ?? false;
    return _hasVibrator!;
  }

  static Future<void> tap() async {
    if (!await _ensureSupport()) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> selection() async {
    if (!await _ensureSupport()) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    if (!await _ensureSupport()) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> warning() async {
    if (!await _ensureSupport()) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> error() async {
    if (!await _ensureSupport()) return;
    await HapticFeedback.vibrate();
  }
}
