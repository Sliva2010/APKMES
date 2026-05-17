// Премиальный экран голосового звонка NOCTIS.
// Демо: имитация состояний (вызов → разговор → завершение).
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';

enum CallState { dialing, active, ended }

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.contactName,
    required this.contactInitials,
    this.video = false,
  });

  final String contactName;
  final String contactInitials;
  final bool video;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with TickerProviderStateMixin {
  CallState _state = CallState.dialing;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _muted = false;
  bool _speaker = false;
  bool _camOff = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    HapticsService.tap();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _state = CallState.active);
      HapticsService.success();
      _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _hangUp() {
    HapticsService.warning();
    setState(() => _state = CallState.ended);
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) context.pop();
    });
  }

  String get _statusText {
    switch (_state) {
      case CallState.dialing:
        return 'Соединение…';
      case CallState.active:
        final int m = _elapsed.inMinutes;
        final int s = _elapsed.inSeconds % 60;
        return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      case CallState.ended:
        return 'Завершено';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // Фоновая «волна» от собеседника.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext _, Widget? __) {
                  return CustomPaint(
                    painter: _BackgroundRings(
                      color: MonochromePalette.guard(
                          theme.colorScheme.onSurface),
                      progress: _pulse.value,
                      active: _state == CallState.active,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.expand_more_rounded),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      Text(
                        widget.video ? 'Видеозвонок' : 'Голосовой звонок',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Container(
                    width: 132,
                    height: 132,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.contactInitials,
                      style: TextStyle(
                        fontFamily: 'NoctisSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 56,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.contactName,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _CallButton(
                        icon: _muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: 'Микро',
                        active: _muted,
                        onTap: () {
                          HapticsService.selection();
                          setState(() => _muted = !_muted);
                        },
                      ),
                      _CallButton(
                        icon: _speaker
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_rounded,
                        label: 'Динамик',
                        active: _speaker,
                        onTap: () {
                          HapticsService.selection();
                          setState(() => _speaker = !_speaker);
                        },
                      ),
                      if (widget.video)
                        _CallButton(
                          icon: _camOff
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          label: 'Камера',
                          active: _camOff,
                          onTap: () {
                            HapticsService.selection();
                            setState(() => _camOff = !_camOff);
                          },
                        )
                      else
                        _CallButton(
                          icon: Icons.message_rounded,
                          label: 'Чат',
                          active: false,
                          onTap: () {
                            HapticsService.tap();
                            context.pop();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _hangUp,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Transform.rotate(
                        angle: 2.36,
                        child: Icon(
                          Icons.call_rounded,
                          color: theme.colorScheme.surface,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: active
                  ? theme.colorScheme.surface
                  : theme.colorScheme.onSurface,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BackgroundRings extends CustomPainter {
  _BackgroundRings({
    required this.color,
    required this.progress,
    required this.active,
  });

  final Color color;
  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.36);
    final double base = size.shortestSide * 0.35;
    for (int i = 0; i < 3; i++) {
      final double t = (progress + i * 0.33) % 1;
      final double radius = base + t * size.height * 0.6;
      final double alpha = (1 - t) * 0.15;
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.0 : 0.5
        ..color = color.withOpacity(alpha);
      canvas.drawCircle(center, radius, p);
    }
    final Paint dot = Paint()..color = color.withOpacity(0.04);
    for (int i = 0; i < 60; i++) {
      final double angle = i * pi / 30;
      final double r = base + 8 + (i % 6) * 4;
      canvas.drawCircle(
        Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r),
        1.2,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundRings old) =>
      old.progress != progress || old.active != active;
}
