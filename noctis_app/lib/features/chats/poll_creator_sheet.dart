// Создание опроса — премиальная шторка NOCTIS.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/primary_button.dart';

class PollDraft {
  PollDraft({
    required this.question,
    required this.options,
    required this.multi,
    required this.anonymous,
  });

  String question;
  List<String> options;
  bool multi;
  bool anonymous;
}

class PollCreatorSheet extends ConsumerStatefulWidget {
  const PollCreatorSheet({super.key, required this.onCreate});

  final ValueChanged<PollDraft> onCreate;

  @override
  ConsumerState<PollCreatorSheet> createState() => _PollCreatorSheetState();
}

class _PollCreatorSheetState extends ConsumerState<PollCreatorSheet> {
  final TextEditingController _question = TextEditingController();
  final List<TextEditingController> _options = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  bool _multi = false;
  bool _anonymous = true;

  @override
  void dispose() {
    _question.dispose();
    for (final TextEditingController c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid {
    if (_question.text.trim().isEmpty) return false;
    final List<String> filled = _options
        .map((TextEditingController c) => c.text.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    return filled.length >= 2;
  }

  void _addOption() {
    if (_options.length >= 10) return;
    HapticsService.tap();
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_options.length <= 2) return;
    HapticsService.warning();
    setState(() {
      _options[i].dispose();
      _options.removeAt(i);
    });
  }

  void _submit() {
    if (!_valid) return;
    HapticsService.success();
    final List<String> filled = _options
        .map((TextEditingController c) => c.text.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    widget.onCreate(PollDraft(
      question: _question.text.trim(),
      options: filled,
      multi: _multi,
      anonymous: _anonymous,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext _, ScrollController controller) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Новый опрос', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: <Widget>[
                      TextField(
                        controller: _question,
                        decoration: const InputDecoration(
                          labelText: 'Вопрос',
                          hintText: 'Как мы проведём вечер?',
                        ),
                        maxLength: 256,
                        maxLines: 2,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Варианты ответа',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (int i = 0; i < _options.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _options[i],
                                  decoration: InputDecoration(
                                    hintText: 'Вариант ${i + 1}',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              if (_options.length > 2)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => _removeOption(i),
                                ),
                            ],
                          ),
                        ),
                      if (_options.length < 10)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: OutlinedButton.icon(
                            onPressed: _addOption,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Добавить вариант'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      _Toggle(
                        title: 'Множественный выбор',
                        subtitle: 'Каждый может выбрать несколько вариантов',
                        value: _multi,
                        onChanged: (bool v) {
                          HapticsService.selection();
                          setState(() => _multi = v);
                        },
                      ),
                      _Toggle(
                        title: 'Анонимный',
                        subtitle: 'Не показывать, кто как голосовал',
                        value: _anonymous,
                        onChanged: (bool v) {
                          HapticsService.selection();
                          setState(() => _anonymous = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Создать опрос',
                  onPressed: _valid ? _submit : null,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: SwitchListTile.adaptive(
        title: Text(title),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.onSurface,
      ),
    );
  }
}
