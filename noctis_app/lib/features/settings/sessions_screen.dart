// Управление активными сессиями.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/animation/haptics_service.dart';
import 'security_state.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final SecurityState state = ref.watch(securityProvider);
    final List<SessionInfo> others =
        state.sessions.where((SessionInfo s) => !s.current).toList();
    final SessionInfo? current = state.sessions.firstWhere(
      (SessionInfo s) => s.current,
      orElse: () => state.sessions.first,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Активные сессии'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
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
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smartphone_rounded,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          current?.device ?? 'Это устройство',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${current?.os ?? ''} · ${current?.location ?? ''}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'СЕЙЧАС',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (others.isNotEmpty) ...<Widget>[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'ДРУГИЕ УСТРОЙСТВА',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticsService.warning();
                        ref
                            .read(securityProvider.notifier)
                            .revokeAllOthers();
                      },
                      child: const Text('Завершить все'),
                    ),
                  ],
                ),
              ),
              ...others.map(
                (SessionInfo s) => _SessionTile(
                  session: s,
                  onRevoke: () {
                    HapticsService.warning();
                    ref.read(securityProvider.notifier).revokeSession(s.id);
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Видите неизвестное устройство?\nЗавершите его и смените облачный пароль',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onRevoke});
  final SessionInfo session;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.devices_other_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(session.device, style: theme.textTheme.titleMedium),
                  Text('${session.os} · ${session.location}',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Активность: ${DateFormat('dd MMM, HH:mm').format(session.lastSeen)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: onRevoke,
            ),
          ],
        ),
      ),
    );
  }
}
