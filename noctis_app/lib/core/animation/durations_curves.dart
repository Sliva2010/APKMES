// Унифицированные длительности и кривые для микроинтеракций NOCTIS.
// Цель: устойчивые 60fps анимации и премиальное ощущение.
import 'package:flutter/animation.dart';

class NoctisDurations {
  const NoctisDurations._();

  /// Быстрая обратная связь на нажатие.
  static const Duration tap = Duration(milliseconds: 100);

  /// Появление элемента списка.
  static const Duration list = Duration(milliseconds: 280);

  /// Переход между экранами.
  static const Duration screen = Duration(milliseconds: 320);

  /// Переключение темы или раскладки.
  static const Duration theme = Duration(milliseconds: 300);

  /// Длинная анимация (модалки, выезжающие панели).
  static const Duration sheet = Duration(milliseconds: 380);
}

class NoctisCurves {
  const NoctisCurves._();

  /// Стандартная кривая дизайн-системы:
  /// эквивалент cubic-bezier(0.4, 0.0, 0.2, 1).
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);

  /// Кривая входа элемента (decelerate).
  static const Curve entrance = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Кривая выхода элемента (accelerate).
  static const Curve exit = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Эластичный отклик на нажатие.
  static const Curve emphasis = Cubic(0.2, 0.0, 0.0, 1.0);
}
