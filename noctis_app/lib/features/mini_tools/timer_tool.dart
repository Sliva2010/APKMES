// Mini_Tool: фокус-таймер с фирменной круговой шкалой.
import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';

class TimerTool extends StatefulWidget {
  const TimerTool({super.key});

  @override
  State<TimerTool> createState() => _TimerToolState();
}

class _TimerToolState extends State<TimerTool> {
  static const List<int> _presets = <int>[5, 10, 15, 25, 45, 60];

  int _totalSeconds = 25 * 60;
  int _remaining = 25 * 60;
  Timer? _ticker;
  bool _running = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _setPreset(int minutes) {
    HapticsService.selection();
    setState(() {
      _totalSeconds = minutes * 60;
      _remaining = minutes * 60;
      _running = false;
      _ticker?.cancel();
    });
  }

  void _toggle() {
    HapticsService.tap();
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _remaining = 0;
          _running = false;
          t.cancel();
          HapticsService.success();
        }
      });
    });
  }

  void _reset() {
    HapticsService.tap();
    setState(() {
      _ticker?.cancel();
      _remaining = _totalSeconds;
      _running = false;
    });
  }

  String _format(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double progress = _totalSeconds == 0
        ? 0.0
        : (_totalSeconds - _remaining) / _totalSeconds;

    return Scaffold(
      appBar: AppBar(title: const Text('Таймер фокуса')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 1),
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        builder:
                            (BuildContext _, double v, Widget? __) =>
                                CircularProgressIndicator(
                          value: v,
                          strokeWidth: 6,
                          color: theme.colorScheme.onSurface,
                          backgroundColor:
                              theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    Text(
                      _format(_remaining),
                      style: TextStyle(
                        fontFamily: 'NoctisSans',
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: MonochromePalette.guard(
                          theme.colorScheme.onSurface,
                        ),
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  for (final int m in _presets)
                    ChoiceChip(
                      label: Text('$m мин'),
                      selected: _totalSeconds == m * 60,
                      onSelected: (_) => _setPreset(m),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Сброс'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _toggle,
                      child: Text(_running ? 'Пауза' : 'Начать'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
