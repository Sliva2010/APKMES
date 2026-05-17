// Приватность: кто видит номер, статус, аватар, может звонить.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import 'security_state.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  static const List<String> _options = <String>['Все', 'Контакты', 'Никто'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final PrivacyVisibility p = ref.watch(securityProvider).privacy;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Приватность'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _SectionHeader(label: 'Кто видит'),
            _Card(
              children: <Widget>[
                _PickerTile(
                  title: 'Время последнего посещения',
                  current: p.lastSeen,
                  options: _options,
                  onPick: (String v) {
                    HapticsService.selection();
                    ref.read(securityProvider.notifier).setPrivacy(
                          p.copyWith(lastSeen: v),
                        );
                  },
                ),
                const Divider(height: 1),
                _PickerTile(
                  title: 'Аватар',
                  current: p.profilePhoto,
                  options: _options,
                  onPick: (String v) {
                    HapticsService.selection();
                    ref.read(securityProvider.notifier).setPrivacy(
                          p.copyWith(profilePhoto: v),
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionHeader(label: 'Кто может'),
            _Card(
              children: <Widget>[
                _PickerTile(
                  title: 'Звонить',
                  current: p.calls,
                  options: _options,
                  onPick: (String v) {
                    HapticsService.selection();
                    ref
                        .read(securityProvider.notifier)
                        .setPrivacy(p.copyWith(calls: v));
                  },
                ),
                const Divider(height: 1),
                _PickerTile(
                  title: 'Пересылать сообщения',
                  current: p.forwards,
                  options: _options,
                  onPick: (String v) {
                    HapticsService.selection();
                    ref
                        .read(securityProvider.notifier)
                        .setPrivacy(p.copyWith(forwards: v));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Эти настройки применяются к новым взаимодействиям. '
              'Существующие чаты могут уже иметь доступ к вашей информации.',
              style: theme.textTheme.bodySmall,
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
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurfaceVariant,
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
        border:
            Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.current,
    required this.options,
    required this.onPick,
  });

  final String title;
  final String current;
  final List<String> options;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(current, style: theme.textTheme.bodyMedium),
      trailing: const Icon(Icons.chevron_right_rounded),
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
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  for (final String o in options)
                    ListTile(
                      title: Text(o),
                      trailing: o == current
                          ? Icon(
                              Icons.check_rounded,
                              color: theme.colorScheme.onSurface,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        onPick(o);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
