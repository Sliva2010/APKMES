// Настройки чатов: размер шрифта, отправка по Enter, обои (заглушка).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/animation/haptics_service.dart';

class ChatsSettingsScreen extends ConsumerStatefulWidget {
  const ChatsSettingsScreen({super.key});

  @override
  ConsumerState<ChatsSettingsScreen> createState() =>
      _ChatsSettingsScreenState();
}

class _ChatsSettingsScreenState extends ConsumerState<ChatsSettingsScreen> {
  double _fontSize = 16;
  bool _sendByEnter = true;
  bool _autoDownload = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      setState(() {
        _fontSize = p.getDouble('noctis.chat.fontSize') ?? 16;
        _sendByEnter = p.getBool('noctis.chat.enterToSend') ?? true;
        _autoDownload = p.getBool('noctis.chat.autoDownload') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setDouble('noctis.chat.fontSize', _fontSize);
      await p.setBool('noctis.chat.enterToSend', _sendByEnter);
      await p.setBool('noctis.chat.autoDownload', _autoDownload);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Чаты'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Text('РАЗМЕР ТЕКСТА',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.4,
                )),
            const SizedBox(height: 8),
            _Card(
              children: <Widget>[
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Так будет выглядеть ваш текст',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: _fontSize,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  child: Slider(
                    min: 12,
                    max: 22,
                    divisions: 10,
                    label: _fontSize.toStringAsFixed(0),
                    value: _fontSize,
                    onChanged: (double v) {
                      setState(() => _fontSize = v);
                    },
                    onChangeEnd: (_) {
                      HapticsService.selection();
                      _persist();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Card(
              children: <Widget>[
                SwitchListTile(
                  secondary: const Icon(Icons.keyboard_return_rounded),
                  title: const Text('Отправка по Enter'),
                  subtitle: const Text('Иначе — перенос строки'),
                  value: _sendByEnter,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    setState(() => _sendByEnter = v);
                    _persist();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.download_rounded),
                  title: const Text('Автозагрузка медиа'),
                  subtitle: const Text(
                      'Автоматически загружать фото и видео в чатах'),
                  value: _autoDownload,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    setState(() => _autoDownload = v);
                    _persist();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }
}
