// Выбор премиум-значков рядом с именем (до 10).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../premium/premium_badges.dart';
import '../premium/premium_state.dart';

class PremiumBadgeScreen extends ConsumerWidget {
  const PremiumBadgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<String> active = ref.watch(premiumBadgesProvider);
    final PremiumState premium = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Значки'),
      ),
      body: SafeArea(
        child: !premium.active
            ? _PremiumLock()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: <Widget>[
                  Text(
                    'Выберите до ${PremiumBadges.maxActive} значков рядом с вашим именем.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Активно: ${active.length} / ${PremiumBadges.maxActive}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    childAspectRatio: 0.86,
                    children: <Widget>[
                      for (final PremiumBadge b in PremiumBadges.all)
                        _BadgeCell(
                          badge: b,
                          active: active.contains(b.id),
                          onTap: () {
                            HapticsService.selection();
                            ref
                                .read(premiumBadgesProvider.notifier)
                                .toggle(b.id);
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

class _BadgeCell extends StatelessWidget {
  const _BadgeCell({
    required this.badge,
    required this.active,
    required this.onTap,
  });

  final PremiumBadge badge;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.onSurface
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              badge.icon,
              size: 28,
              color: active
                  ? theme.colorScheme.surface
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 6),
            Text(
              badge.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: active
                    ? theme.colorScheme.surface
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumLock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.workspace_premium_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Доступно с Premium',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Оформите подписку, чтобы выбрать до 10 значков\nрядом с вашим именем.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                HapticsService.tap();
                context.push('/premium');
              },
              child: const Text('Открыть Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
