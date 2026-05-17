// HubShell — нижняя навигация NOCTIS.
// Только две вкладки: Чаты и Настройки. Без подписей, только иконки.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';

class HubShell extends StatelessWidget {
  const HubShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const List<_Tab> _tabs = <_Tab>[
    _Tab(
      outlined: Icons.chat_bubble_outline_rounded,
      filled: Icons.chat_bubble_rounded,
    ),
    _Tab(
      outlined: Icons.tune_rounded,
      filled: Icons.tune_rounded,
    ),
  ];

  void _go(int index) {
    HapticsService.selection();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 4, 48, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: MonochromePalette.guard(
                          theme.colorScheme.onSurface)
                      .withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      tab: _tabs[i],
                      selected: navigationShell.currentIndex == i,
                      onTap: () => _go(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.outlined, required this.filled});
  final IconData outlined;
  final IconData filled;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: NoctisDurations.tap,
        curve: NoctisCurves.standard,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Icon(
          selected ? tab.filled : tab.outlined,
          size: 22,
          color: selected
              ? theme.colorScheme.surface
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
