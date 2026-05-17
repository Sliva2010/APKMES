// Многошаговый онбординг NOCTIS — три страницы с фирменными
// иллюстрациями и плавными переходами.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';
import '../../ui/widgets/primary_button.dart';
import 'welcome_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_Slide> _slides = <_Slide>[
    _Slide(
      title: 'Только чёрное\nи белое',
      body:
          'Премиальный мессенджер без визуального шума. Ничего лишнего —\nтолько форма и слово.',
      illustration: _Illustration.crescent,
    ),
    _Slide(
      title: 'Скорость\nи приватность',
      body:
          'Сквозное шифрование, исчезающие сообщения, биометрический замок.\nВсё под вашим контролем.',
      illustration: _Illustration.shield,
    ),
    _Slide(
      title: 'Один интерфейс\nдля iOS и Android',
      body:
          '60 fps анимации, тактильный отклик, мгновенный отклик.\nNOCTIS живёт в ваших руках.',
      illustration: _Illustration.devices,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    HapticsService.tap();
    if (_index == _slides.length - 1) {
      context.go('/welcome');
      return;
    }
    _controller.nextPage(
      duration: NoctisDurations.screen,
      curve: NoctisCurves.standard,
    );
  }

  void _skip() {
    HapticsService.selection();
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: WelcomeBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: <Widget>[
                    Text(
                      'NOCTIS',
                      style: TextStyle(
                        fontFamily: 'NoctisSans',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                        color: MonochromePalette.guard(
                            theme.colorScheme.onSurface),
                      ),
                    ),
                    const Spacer(),
                    if (_index < _slides.length - 1)
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Пропустить',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (int i) {
                    setState(() => _index = i);
                    HapticsService.selection();
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return _SlideView(slide: _slides[index]);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: NoctisDurations.tap,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: PrimaryButton(
                  label: _index == _slides.length - 1
                      ? 'Начать'
                      : 'Дальше',
                  onPressed: _next,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Illustration { crescent, shield, devices }

class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String title;
  final String body;
  final _Illustration illustration;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
      child: Column(
        children: <Widget>[
          const Spacer(flex: 1),
          SizedBox(
            width: 240,
            height: 240,
            child: _IllustrationView(slide.illustration),
          ),
          const Spacer(flex: 1),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(height: 1.05),
          ),
          const SizedBox(height: 14),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _IllustrationView extends StatefulWidget {
  const _IllustrationView(this.kind);
  final _Illustration kind;

  @override
  State<_IllustrationView> createState() => _IllustrationViewState();
}

class _IllustrationViewState extends State<_IllustrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext _, Widget? __) {
        return CustomPaint(
          painter: _IllustrationPainter(
            kind: widget.kind,
            t: _c.value,
            primary: MonochromePalette.guard(theme.colorScheme.onSurface),
            background:
                MonochromePalette.guard(theme.scaffoldBackgroundColor),
            soft: theme.colorScheme.outlineVariant,
          ),
        );
      },
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter({
    required this.kind,
    required this.t,
    required this.primary,
    required this.background,
    required this.soft,
  });

  final _Illustration kind;
  final double t;
  final Color primary;
  final Color background;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case _Illustration.crescent:
        _paintCrescent(canvas, size);
        break;
      case _Illustration.shield:
        _paintShield(canvas, size);
        break;
      case _Illustration.devices:
        _paintDevices(canvas, size);
        break;
    }
  }

  void _paintCrescent(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2 - 8;

    final Paint outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = soft;
    canvas.drawCircle(center, r, outer);
    canvas.drawCircle(center, r * 0.82, outer);

    canvas.drawCircle(center, r * 0.6, Paint()..color = primary);
    canvas.drawCircle(
      center.translate(r * (0.18 + 0.04 * t), -r * 0.05),
      r * 0.55,
      Paint()..color = background,
    );

    // Точки-звёзды.
    final Paint dot = Paint()..color = primary.withOpacity(0.7);
    canvas.drawCircle(center.translate(-r * 0.7, -r * 0.5), 2.5, dot);
    canvas.drawCircle(center.translate(r * 0.65, r * 0.55), 1.8, dot);
    canvas.drawCircle(center.translate(-r * 0.55, r * 0.7), 2.0, dot);
  }

  void _paintShield(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path path = Path()
      ..moveTo(w / 2, h * 0.05)
      ..lineTo(w * 0.92, h * 0.22)
      ..lineTo(w * 0.92, h * 0.55)
      ..quadraticBezierTo(w * 0.92, h * 0.92, w / 2, h * 0.95)
      ..quadraticBezierTo(w * 0.08, h * 0.92, w * 0.08, h * 0.55)
      ..lineTo(w * 0.08, h * 0.22)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = primary,
    );

    // Внутренняя «галочка».
    final Paint check = Paint()
      ..color = background
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.32, h * 0.5)
        ..lineTo(w * 0.46, h * 0.62)
        ..lineTo(w * 0.7, h * 0.36),
      check,
    );

    // Внешний «отблеск» — пульсирует.
    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = primary.withOpacity(0.18 + t * 0.18);
    final Path outer = Path()..addPath(path, Offset.zero);
    canvas.drawPath(outer, glow);
  }

  void _paintDevices(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Большой экран (ноутбук).
    final RRect lap = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.82, h * 0.46),
      const Radius.circular(8),
    );
    canvas.drawRRect(lap, Paint()..color = primary);
    final RRect lapBase = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.66, w * 0.92, h * 0.04),
      const Radius.circular(4),
    );
    canvas.drawRRect(lapBase, Paint()..color = primary);

    // Внутренний экран.
    final RRect lapInner = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.74, h * 0.38),
      const Radius.circular(4),
    );
    canvas.drawRRect(lapInner, Paint()..color = background);

    // Линии-сообщения.
    final Paint line = Paint()
      ..color = primary.withOpacity(0.6)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.18, h * 0.32),
      Offset(w * 0.5 + 30 * t, h * 0.32),
      line,
    );
    canvas.drawLine(
      Offset(w * 0.18, h * 0.42),
      Offset(w * 0.65 - 20 * t, h * 0.42),
      line,
    );
    canvas.drawLine(
      Offset(w * 0.18, h * 0.52),
      Offset(w * 0.42, h * 0.52),
      line,
    );

    // Телефон.
    final RRect phone = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.62, h * 0.5, w * 0.28, h * 0.5),
      const Radius.circular(14),
    );
    canvas.drawRRect(phone, Paint()..color = background);
    canvas.drawRRect(
      phone,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = primary,
    );
    final RRect phoneScreen = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.66, h * 0.55, w * 0.20, h * 0.40),
      const Radius.circular(8),
    );
    canvas.drawRRect(phoneScreen, Paint()..color = primary);

    // «Полоски» в телефоне.
    final Paint phoneLine = Paint()
      ..color = background
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.69, h * 0.62),
      Offset(w * 0.78 + 6 * t, h * 0.62),
      phoneLine,
    );
    canvas.drawLine(
      Offset(w * 0.69, h * 0.7),
      Offset(w * 0.83 - 4 * t, h * 0.7),
      phoneLine,
    );
    canvas.drawLine(
      Offset(w * 0.69, h * 0.78),
      Offset(w * 0.81, h * 0.78),
      phoneLine,
    );
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter old) =>
      old.kind != kind || old.t != t || old.primary != primary;
}
