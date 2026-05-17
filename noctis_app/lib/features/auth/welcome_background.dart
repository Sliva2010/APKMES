// Анимированный монохромный фон welcome-экранов:
// плавно дрейфующая сетка точек + два лунных диска,
// проявляющиеся друг сквозь друга.
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/monochrome_palette.dart';

class WelcomeBackground extends StatefulWidget {
  const WelcomeBackground({super.key, required this.child});
  final Widget child;

  @override
  State<WelcomeBackground> createState() => _WelcomeBackgroundState();
}

class _WelcomeBackgroundState extends State<WelcomeBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _drift,
            builder: (BuildContext _, Widget? __) => CustomPaint(
              painter: _DriftPainter(
                color: MonochromePalette.guard(theme.colorScheme.onSurface),
                background: theme.scaffoldBackgroundColor,
                t: _drift.value,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _DriftPainter extends CustomPainter {
  _DriftPainter({
    required this.color,
    required this.background,
    required this.t,
  });

  final Color color;
  final Color background;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Сетка точек.
    final Paint dotPaint = Paint()..color = color.withOpacity(0.05);
    const double step = 28;
    final double offsetX = (t * step) % step;
    final double offsetY = (sin(t * pi * 2) * 6);
    for (double x = -step + offsetX; x < size.width + step; x += step) {
      for (double y = -step + offsetY; y < size.height + step; y += step) {
        canvas.drawCircle(Offset(x, y), 0.9, dotPaint);
      }
    }

    // Большая «луна» в правом верхнем углу.
    final double moonR = size.shortestSide * 0.6;
    final Offset moonCenter = Offset(
      size.width * 0.85 + sin(t * pi * 2) * 16,
      size.height * 0.18 + cos(t * pi * 2) * 12,
    );
    final Paint moonStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withOpacity(0.07)
      ..strokeWidth = 0.7;
    canvas.drawCircle(moonCenter, moonR, moonStroke);
    canvas.drawCircle(moonCenter, moonR * 0.78, moonStroke);
    canvas.drawCircle(moonCenter, moonR * 0.55, moonStroke);

    // Малая «луна» внизу слева.
    final double smallR = size.shortestSide * 0.35;
    final Offset smallCenter = Offset(
      -size.width * 0.05 + cos(t * pi * 2) * 18,
      size.height * 0.92 + sin(t * pi * 2) * 10,
    );
    canvas.drawCircle(smallCenter, smallR, moonStroke);
    canvas.drawCircle(smallCenter, smallR * 0.7, moonStroke);
  }

  @override
  bool shouldRepaint(covariant _DriftPainter old) =>
      old.t != t || old.color != color;
}
