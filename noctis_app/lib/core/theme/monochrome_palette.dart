// Монохромная палитра NOCTIS.
// Все цвета приложения должны быть оттенками серого:
// (R == G == B). Любой цветной токен — ошибка дизайна.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class MonochromePalette {
  const MonochromePalette._();

  // Базовые точки палитры — оттенки серого от чёрного к белому.
  static const Color black = Color(0xFF000000);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color obsidian = Color(0xFF111111);
  static const Color graphite = Color(0xFF1A1A1A);
  static const Color slate = Color(0xFF242424);
  static const Color iron = Color(0xFF2E2E2E);
  static const Color steel = Color(0xFF3A3A3A);
  static const Color stone = Color(0xFF555555);
  static const Color ash = Color(0xFF7A7A7A);
  static const Color smoke = Color(0xFFA0A0A0);
  static const Color silver = Color(0xFFC4C4C4);
  static const Color pearl = Color(0xFFE3E3E3);
  static const Color paper = Color(0xFFF2F2F2);
  static const Color porcelain = Color(0xFFF8F8F8);
  static const Color white = Color(0xFFFFFFFF);

  /// Проверяет, что цвет принадлежит монохромной палитре.
  /// В debug — assertion, в release — лог и подмена на ближайший серый.
  static Color guard(Color c) {
    final int r = c.red;
    final int g = c.green;
    final int b = c.blue;
    if (r == g && g == b) {
      return c;
    }
    assert(() {
      // ignore: avoid_print
      debugPrint('MonochromePalette.guard: non-grayscale color: $c');
      return true;
    }());
    final int avg = (r + g + b) ~/ 3;
    return Color.fromARGB(c.alpha, avg, avg, avg);
  }

  /// Линейная интерполяция между двумя серыми.
  static Color lerpGray(Color a, Color b, double t) {
    return Color.lerp(guard(a), guard(b), t.clamp(0.0, 1.0))!;
  }
}
