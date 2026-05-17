// Палитра стикеров — пять монохромных наборов в стилистике NOCTIS.
import 'package:flutter/material.dart';

import '../../core/animation/haptics_service.dart';

class StickerPicker extends StatelessWidget {
  const StickerPicker({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  static const List<List<String>> _packs = <List<String>>[
    <String>['◼︎', '◻︎', '◼︎ ◻︎', '⬛︎', '⬜︎', '▣', '▤', '▥', '▦', '▧', '▨', '▩'],
    <String>['☺︎', '☹︎', '♥︎', '♡', '✦', '✧', '✩', '✪', '☾', '☼', '☁︎', '☂︎'],
    <String>['→', '←', '↑', '↓', '↗︎', '↘︎', '↪︎', '⤴︎', '✓', '✗', '★', '☆'],
    <String>['¡', '?', '!', '...', '—', '«»', '"', '·', '•', '◦', '∞', '§'],
    <String>['NOCTIS', 'TONIGHT', 'ONLY YOU', 'IN THE DARK', 'STAY', 'BREATHE',
            'WHITE', 'BLACK', 'SILENCE', 'BRIGHT', 'WAIT', 'NOW'],
  ];

  static const List<String> _packLabels = <String>[
    'Геометрия',
    'Символы',
    'Стрелки',
    'Знаки',
    'Слова',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DefaultTabController(
      length: _packs.length,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 340,
          child: Column(
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
              TabBar(
                isScrollable: true,
                indicatorColor: theme.colorScheme.onSurface,
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: theme.textTheme.labelLarge,
                tabs: <Widget>[
                  for (final String l in _packLabels) Tab(text: l),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    for (final List<String> pack in _packs)
                      GridView.count(
                        padding: const EdgeInsets.all(12),
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: <Widget>[
                          for (final String s in pack)
                            _StickerCell(
                              text: s,
                              onTap: () {
                                HapticsService.selection();
                                onPick(s);
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerCell extends StatelessWidget {
  const _StickerCell({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isWord = text.length > 4;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NoctisSans',
              fontSize: isWord ? 14 : 30,
              fontWeight: isWord ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: isWord ? 1.5 : 0,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
