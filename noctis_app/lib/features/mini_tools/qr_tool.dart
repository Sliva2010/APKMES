// QR-генератор: чёрно-белая матрица из пакета `qr`.
// Сканируется любым QR-ридером.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';

class QrTool extends StatefulWidget {
  const QrTool({super.key});

  @override
  State<QrTool> createState() => _QrToolState();
}

class _QrToolState extends State<QrTool> {
  final TextEditingController _controller =
      TextEditingController(text: 'https://noctis.app');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String text = _controller.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('QR-код')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Center(
                child: AnimatedSwitcher(
                  duration: NoctisDurations.list,
                  switchInCurve: NoctisCurves.standard,
                  switchOutCurve: NoctisCurves.standard,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: NoctisCurves.standard,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey<String>(text),
                    width: 280,
                    height: 280,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MonochromePalette.guard(
                          theme.scaffoldBackgroundColor),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: text.isEmpty
                        ? Center(
                            child: Text(
                              'Введите текст,\nчтобы создать код',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        : CustomPaint(
                            painter: _QrPainter(
                              data: text,
                              foreground: MonochromePalette.guard(
                                theme.colorScheme.onSurface,
                              ),
                              background: MonochromePalette.guard(
                                theme.scaffoldBackgroundColor,
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Текст или ссылка',
                  hintText: 'https://example.com',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: text.isEmpty
                          ? null
                          : () {
                              HapticsService.tap();
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Скопировано',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Копировать'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticsService.tap();
                        _controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Очистить'),
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

class _QrPainter extends CustomPainter {
  _QrPainter({
    required this.data,
    required this.foreground,
    required this.background,
  });

  final String data;
  final Color foreground;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    QrCode code;
    try {
      code = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
    } catch (_) {
      // Слишком длинная строка — отрисуем заглушку.
      canvas.drawRect(Offset.zero & size, Paint()..color = background);
      return;
    }
    final QrImage image = QrImage(code);
    final int n = image.moduleCount;
    final double cell = size.shortestSide / n;

    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final Paint dark = Paint()..color = foreground;
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (image.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
            dark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) =>
      old.data != data ||
      old.foreground != foreground ||
      old.background != background;
}
