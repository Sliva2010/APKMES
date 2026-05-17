// Экран настроек: переключение темы и базовые опции.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../core/theme/theme_engine.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NoctisThemeMode mode = ref.watch(themeModeProvider);
    final AuthState auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Настройки'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _SectionHeader(label: 'Профиль'),
            _Tile(
              title: auth.displayName ?? 'Без имени',
              subtitle: auth.username == null ? '—' : '@${auth.username}',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            _SectionHeader(label: 'Внешний вид'),
            _ThemeSelector(
              current: mode,
              onChange: (NoctisThemeMode m) {
                HapticsService.tap();
                ref.read(themeModeProvider.notifier).state = m;
              },
            ),
            const SizedBox(height: 12),
            _SectionHeader(label: 'Инструменты'),
            _Tile(
              title: 'Мини-инструменты',
              subtitle: 'Калькулятор, таймер, переводчик',
              icon: Icons.dashboard_customize_outlined,
              onTap: () => context.push('/tools'),
            ),
            const SizedBox(height: 12),
            _SectionHeader(label: 'Безопасность'),
            _Tile(
              title: 'Двухфакторная аутентификация',
              subtitle: 'Облачный пароль',
              icon: Icons.lock_outline_rounded,
              onTap: () {},
            ),
            _Tile(
              title: 'Активные сессии',
              subtitle: 'Управление вошедшими устройствами',
              icon: Icons.devices_other_rounded,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SectionHeader(label: 'Аккаунт'),
            _Tile(
              title: 'Выйти',
              icon: Icons.logout_rounded,
              destructive: true,
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/welcome');
                }
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'NOCTIS · 1.0.0',
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        destructive ? theme.colorScheme.onSurface : theme.colorScheme.onSurface;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, color: color),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChange});
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

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: <Widget>[
          chip(NoctisThemeMode.system, 'Авто', Icons.brightness_auto_rounded),
          const SizedBox(width: 8),
          chip(NoctisThemeMode.light, 'Свет', Icons.light_mode_outlined),
          const SizedBox(width: 8),
          chip(NoctisThemeMode.dark, 'Ночь', Icons.dark_mode_outlined),
        ],
      ),
    );
  }
}
