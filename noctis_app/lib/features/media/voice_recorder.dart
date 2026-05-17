// Записчик голосовых сообщений (демо).
// Имитирует запись с пиками громкости — для UX-полировки до подключения
// нативного бэкенда записи.
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';

class VoiceRecorderResult {
  const VoiceRecorderResult({
    required this.duration,
    required this.waveform,
  });

  final Duration duration;
  final List<double> waveform;
}

class VoiceRecorderSheet extends StatefulWidget {
  const VoiceRecorderSheet({super.key, required this.onComplete});

  final ValueChanged<VoiceRecorderResult> onComplete;

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  final List<double> _samples = <double>[];
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    HapticsService.selection();
    _ticker =
        Timer.periodic(const Duration(milliseconds: 80), (Timer t) {
      if (!mounted) return;
      setState(() {
        _elapsed += const Duration(milliseconds: 80);
        // Плавно колеблющаяся «громкость».
        final double base =
            0.35 + 0.5 * sin(_elapsed.inMilliseconds / 250);
        final double noise = (_rand.nextDouble() - 0.5) * 0.4;
        _samples.add((base + noise).clamp(0.05, 1.0));
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _stop({required bool send}) {
    _ticker?.cancel();
    HapticsService.success();
    if (send && _samples.length > 4) {
      widget.onComplete(VoiceRecorderResult(
        duration: _elapsed,
        waveform: List<double>.unmodifiable(_samples),
      ));
    }
    Navigator.of(context).maybePop();
  }

  String _format(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Запись', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              _format(_elapsed),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: CustomPaint(
                size: Size.fromHeight(56),
                painter: _LiveWaveform(
                  samples: _samples,
                  color: MonochromePalette.guard(theme.colorScheme.onSurface),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _CircleButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: () => _stop(send: false),
                ),
                _RecordPulse(),
                _CircleButton(
                  icon: Icons.send_rounded,
                  filled: true,
                  onTap: () => _stop(send: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: filled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: filled
              ? theme.colorScheme.surface
              : theme.colorScheme.onSurface,
          size: 22,
        ),
      ),
    );
  }
}

class _RecordPulse extends StatefulWidget {
  @override
  State<_RecordPulse> createState() => _RecordPulseState();
}

class _RecordPulseState extends State<_RecordPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
        return Container(
          width: 64 + 12 * _c.value,
          height: 64 + 12 * _c.value,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_rounded,
              color: theme.colorScheme.surface,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

class _LiveWaveform extends CustomPainter {
  _LiveWaveform({required this.samples, required this.color});
  final List<double> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    final Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    const double barWidth = 3;
    const double gap = 3;
    final double total = barWidth + gap;
    final int max = (size.width / total).floor();
    final List<double> tail = samples.length > max
        ? samples.sublist(samples.length - max)
        : samples;
    final double startX = size.width - tail.length * total;
    for (int i = 0; i < tail.length; i++) {
      final double h = tail[i] * size.height;
      final double x = startX + i * total + barWidth / 2;
      final double cy = size.height / 2;
      canvas.drawLine(
        Offset(x, cy - h / 2),
        Offset(x, cy + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveWaveform old) =>
      old.samples != samples || old.color != color;
}

class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.samples,
    required this.color,
    required this.played,
  });

  final List<double> samples;
  final Color color;

  /// 0..1 — доля «проигранной» части.
  final double played;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    const double barWidth = 2;
    const double gap = 2;
    final double total = barWidth + gap;
    final int n = (size.width / total).floor();
    final List<double> resampled = <double>[];
    final double step = samples.length / n;
    for (int i = 0; i < n; i++) {
      final int idx = (i * step).floor().clamp(0, samples.length - 1);
      resampled.add(samples[idx]);
    }
    final double playedPx = size.width * played;
    final Paint p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (int i = 0; i < resampled.length; i++) {
      final double h = resampled[i] * size.height;
      final double x = i * total + barWidth / 2;
      final double cy = size.height / 2;
      p.color = x <= playedPx ? color : color.withOpacity(0.35);
      canvas.drawLine(
        Offset(x, cy - h / 2),
        Offset(x, cy + h / 2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter old) =>
      old.samples != samples ||
      old.color != color ||
      old.played != played;
}
