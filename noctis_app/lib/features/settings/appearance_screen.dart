// Экран выбора темы и палитры (Pure White / Pure Black / Graphite / Paper).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/theme_engine.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NoctisThemeMode mode = ref.watch(themeModeProvider);
    final NoctisThemePalette light = ref.watch(lightPaletteProvider);
    final NoctisThemePalette dark = ref.watch(darkPaletteProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Внешний вид'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _SectionHeader(label: 'Режим'),
            _ModeSelector(
              current: mode,
              onChange: (NoctisThemeMode m) {
                HapticsService.tap();
                ref.read(themeModeProvider.notifier).state = m;
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(label: 'Светлая палитра'),
            for (final NoctisThemePalette p in <NoctisThemePalette>[
              NoctisThemePalette.pureWhite,
              NoctisThemePalette.paper,
            ])
              _PaletteTile(
                palette: p,
                selected: light == p,
                onTap: () {
                  HapticsService.selection();
                  ref.read(lightPaletteProvider.notifier).state = p;
                },
              ),
            const SizedBox(height: 24),
            _SectionHeader(label: 'Тёмная палитра'),
            for (final NoctisThemePalette p in <NoctisThemePalette>[
              NoctisThemePalette.pureBlack,
              NoctisThemePalette.graphite,
            ])
              _PaletteTile(
                palette: p,
                selected: dark == p,
                onTap: () {
                  HapticsService.selection();
                  ref.read(darkPaletteProvider.notifier).state = p;
                },
              ),
            const SizedBox(height: 28),
            Center(
              child: Text(
                'Все темы — строго в монохроме',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.current, required this.onChange});
  final NoctisThemeMode current;
  final ValueChanged<NoctisThemeMode> onChange;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Widget chip(NoctisThemeMode mode, String label, IconData icon) {
      final bool selected = current == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChange(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? theme.colorScheme.surface
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? theme.colorScheme.surface
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        chip(NoctisThemeMode.system, 'Авто', Icons.brightness_auto_rounded),
        const SizedBox(width: 8),
        chip(NoctisThemeMode.light, 'Свет', Icons.light_mode_outlined),
        const SizedBox(width: 8),
        chip(NoctisThemeMode.dark, 'Ночь', Icons.dark_mode_outlined),
      ],
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final NoctisThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData preview = ThemeEngine.buildFor(palette);
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: NoctisDurations.tap,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: preview.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: preview.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: preview.colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        palette.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        palette.isDark
                            ? 'Тёмная монохромная палитра'
                            : 'Светлая монохромная палитра',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
