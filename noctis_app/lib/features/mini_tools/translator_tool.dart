// Mini_Tool: переводчик (демо-словарь, без сети).
// Поддерживает короткие фразы между ru ↔ en ↔ es ↔ de ↔ fr.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';

const Map<String, String> _languageLabels = <String, String>{
  'ru': 'Русский',
  'en': 'English',
  'es': 'Español',
  'de': 'Deutsch',
  'fr': 'Français',
};

const Map<String, Map<String, String>> _phrasebook = <String, Map<String, String>>{
  'привет': <String, String>{
    'en': 'Hello',
    'es': 'Hola',
    'de': 'Hallo',
    'fr': 'Bonjour',
  },
  'спасибо': <String, String>{
    'en': 'Thank you',
    'es': 'Gracias',
    'de': 'Danke',
    'fr': 'Merci',
  },
  'пожалуйста': <String, String>{
    'en': 'Please',
    'es': 'Por favor',
    'de': 'Bitte',
    'fr': 'S’il vous plaît',
  },
  'да': <String, String>{
    'en': 'Yes',
    'es': 'Sí',
    'de': 'Ja',
    'fr': 'Oui',
  },
  'нет': <String, String>{
    'en': 'No',
    'es': 'No',
    'de': 'Nein',
    'fr': 'Non',
  },
  'доброе утро': <String, String>{
    'en': 'Good morning',
    'es': 'Buenos días',
    'de': 'Guten Morgen',
    'fr': 'Bonjour',
  },
  'спокойной ночи': <String, String>{
    'en': 'Good night',
    'es': 'Buenas noches',
    'de': 'Gute Nacht',
    'fr': 'Bonne nuit',
  },
  'как дела': <String, String>{
    'en': 'How are you',
    'es': 'Cómo estás',
    'de': 'Wie geht es dir',
    'fr': 'Comment ça va',
  },
  'я тебя люблю': <String, String>{
    'en': 'I love you',
    'es': 'Te quiero',
    'de': 'Ich liebe dich',
    'fr': 'Je t’aime',
  },
  'до свидания': <String, String>{
    'en': 'Goodbye',
    'es': 'Adiós',
    'de': 'Auf Wiedersehen',
    'fr': 'Au revoir',
  },
};

class TranslatorTool extends StatefulWidget {
  const TranslatorTool({super.key});

  @override
  State<TranslatorTool> createState() => _TranslatorToolState();
}

class _TranslatorToolState extends State<TranslatorTool> {
  final TextEditingController _input =
      TextEditingController(text: 'Привет');
  String _from = 'ru';
  String _to = 'en';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _translate(String text) {
    final String key = text.trim().toLowerCase();
    if (key.isEmpty) return '';
    if (_from == _to) return text;
    if (_from == 'ru') {
      return _phrasebook[key]?[_to] ?? '— перевод не найден';
    }
    // Реверс: en/es/de/fr → ru
    for (final MapEntry<String, Map<String, String>> e
        in _phrasebook.entries) {
      if (e.value[_from]?.toLowerCase() == key) {
        if (_to == 'ru') return e.key[0].toUpperCase() + e.key.substring(1);
        return e.value[_to] ?? '— перевод не найден';
      }
    }
    return '— перевод не найден';
  }

  void _swap() {
    HapticsService.selection();
    setState(() {
      final String tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String result = _translate(_input.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Переводчик')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: _LangPicker(
                    code: _from,
                    onChange: (String c) {
                      HapticsService.selection();
                      setState(() => _from = c);
                    },
                  )),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _swap,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _LangPicker(
                    code: _to,
                    onChange: (String c) {
                      HapticsService.selection();
                      setState(() => _to = c);
                    },
                  )),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _input,
                  maxLines: 4,
                  minLines: 2,
                  style: theme.textTheme.titleMedium,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: 'Введите текст для перевода',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: NoctisDurations.list,
                child: Container(
                  key: ValueKey<String>(result),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            _languageLabels[_to]!.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color:
                                  theme.colorScheme.surface.withOpacity(0.7),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          if (result.isNotEmpty &&
                              !result.startsWith('—'))
                            GestureDetector(
                              onTap: () {
                                HapticsService.tap();
                                Clipboard.setData(
                                    ClipboardData(text: result));
                              },
                              child: Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: theme.colorScheme.surface
                                    .withOpacity(0.85),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.isEmpty ? '—' : result,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.surface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Демо-словарь. Подключение онлайн-движка переводов планируется.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangPicker extends StatelessWidget {
  const _LangPicker({required this.code, required this.onChange});
  final String code;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (BuildContext sheetCtx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 12),
                  for (final MapEntry<String, String> e
                      in _languageLabels.entries)
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: Text(e.value),
                      trailing: e.key == code
                          ? Icon(Icons.check_rounded,
                              color: theme.colorScheme.onSurface)
                          : null,
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        onChange(e.key);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.language_rounded,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _languageLabels[code] ?? code,
                style: theme.textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
