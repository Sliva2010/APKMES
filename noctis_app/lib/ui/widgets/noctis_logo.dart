// Лого NOCTIS — премиальная монохромная марка.
// Плавная пульсация круга-«луны» создаёт фирменное ощущение.
import 'package:flutter/material.dart';

import '../../core/theme/monochrome_palette.dart';

class NoctisLogo extends StatefulWidget {
  const NoctisLogo({
    super.key,
    this.size = 96,
    this.label = true,
  });

  final double size;
  final bool label;

  @override
  State<NoctisLogo> createState() => _NoctisLogoState();
}

class _NoctisLogoState extends State<NoctisLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            final double t = _controller.value;
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _MoonPainter(
                  primary: scheme.onSurface,
                  background: scheme.surface,
                  phase: t,
                ),
              ),
            );
          },
        ),
        if (widget.label) ...<Widget>[
          const SizedBox(height: 18),
          Text(
            'NOCTIS',
            style: TextStyle(
              fontFamily: 'NoctisSans',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 12,
              color: MonochromePalette.guard(scheme.onSurface),
            ),
          ),
        ],
      ],
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({
    required this.primary,
    required this.background,
    required this.phase,
  });

  final Color primary;
  final Color background;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2;

    final Paint outline = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(center, radius - 0.7, outline);

    final double cutoutDx = radius * (0.45 + 0.18 * phase);
    final Paint cutout = Paint()..color = primary;
    canvas.drawCircle(
      center.translate(cutoutDx * 0.55, -radius * 0.05),
      radius * 0.86,
      cutout,
    );
    canvas.drawCircle(
      center.translate(cutoutDx, -radius * 0.05),
      radius * 0.86,
      Paint()..color = background,
    );
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.primary != primary ||
        oldDelegate.background != background;
  }
}
