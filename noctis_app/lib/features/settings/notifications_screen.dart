// Уведомления и звуки.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../core/permissions/permission_service.dart';
import 'notifications_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final NotificationsState s = ref.watch(notificationsProvider);
    final NotificationsController c =
        ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Уведомления и звуки'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _Card(
              children: <Widget>[
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Уведомления приложения'),
                  subtitle: const Text(
                      'Показывать на экране при сообщениях и звонках'),
                  value: s.systemNotifications,
                  onChanged: (bool v) async {
                    HapticsService.selection();
                    if (v) {
                      final bool ok =
                          await PermissionService.ensureNotifications();
                      c.setSystemNotifications(ok);
                    } else {
                      c.setSystemNotifications(false);
                    }
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.preview_outlined),
                  title: const Text('Превью сообщения'),
                  subtitle: const Text('Показывать текст в уведомлении'),
                  value: s.preview,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    c.setPreview(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('ЗВУКИ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.4,
                )),
            const SizedBox(height: 8),
            _Card(
              children: <Widget>[
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Звук сообщений'),
                  subtitle: const Text(
                      'Лёгкий «дзинь» при отправке и получении'),
                  value: s.messageSounds,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    c.setMessageSounds(v);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.ring_volume_outlined),
                  title: const Text('Гудки звонка'),
                  subtitle: const Text('Звук и вибрация при вызове'),
                  value: s.callRingtone,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    c.setCallRingtone(v);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text('Вибрация'),
                  subtitle:
                      const Text('Тактильная отдача и виброкольцо звонков'),
                  value: s.vibration,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    c.setVibration(v);
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
