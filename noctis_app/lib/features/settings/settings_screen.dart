// Главный экран настроек.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../auth/auth_controller.dart';
import '../premium/premium_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AuthState auth = ref.watch(authControllerProvider);
    final PremiumState premium = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Настройки'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: <Widget>[
            _ProfileCard(auth: auth, premium: premium),
            const SizedBox(height: 16),
            if (!premium.active) ...<Widget>[
              _PremiumPromoCard(
                onTap: () => context.push('/premium'),
              ),
              const SizedBox(height: 16),
            ],
            _Card(
              children: <Widget>[
                _Tile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Внешний вид',
                  subtitle: 'Темы и палитры',
                  onTap: () => context.push('/settings/appearance'),
                ),
                const Divider(height: 1),
                _Tile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Безопасность',
                  subtitle: 'App Lock, биометрия, 2FA',
                  onTap: () => context.push('/settings/security'),
                ),
                const Divider(height: 1),
                _Tile(
                  icon: Icons.shield_outlined,
                  title: 'Приватность',
                  subtitle: 'Кто видит ваши данные',
                  onTap: () => context.push('/settings/privacy'),
                ),
                const Divider(height: 1),
                _Tile(
                  icon: Icons.devices_other_rounded,
                  title: 'Устройства',
                  subtitle: 'Активные сессии',
                  onTap: () => context.push('/settings/sessions'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Card(
              children: <Widget>[
                _Tile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'NOCTIS Premium',
                  subtitle: premium.active
                      ? premium.plan == PremiumPlan.annual
                          ? 'Годовой · активен'
                          : 'Месячный · активен'
                      : 'Безлимит и эксклюзивные фичи',
                  onTap: () => context.push('/premium'),
                ),
                const Divider(height: 1),
                _Tile(
                  icon: Icons.info_outline_rounded,
                  title: 'О NOCTIS',
                  subtitle: 'Версия 1.0.0',
                  onTap: () {
                    HapticsService.tap();
                    showAboutDialog(
                      context: context,
                      applicationName: 'NOCTIS',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Премиальный кроссплатформенный мессенджер.\nMIT License.',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Card(
              children: <Widget>[
                _Tile(
                  icon: Icons.logout_rounded,
                  title: 'Выйти',
                  destructive: true,
                  onTap: () async {
                    HapticsService.warning();
                    await ref
                        .read(authControllerProvider.notifier)
                        .logout();
                    if (context.mounted) {
                      context.go('/welcome');
                    }
                  },
                ),
              ],
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.auth, required this.premium});
  final AuthState auth;
  final PremiumState premium;

  String get _initials {
    final String name = auth.displayName ?? '';
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'N';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.surface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        auth.displayName ?? 'Без имени',
                        style: theme.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (premium.active) ...<Widget>[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  auth.username == null
                      ? auth.phoneE164 ?? '—'
                      : '@${auth.username}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _PremiumPromoCard extends StatelessWidget {
  const _PremiumPromoCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticsService.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: theme.colorScheme.onSurface,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Откройте Premium',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Безлимиты, темы и расширенные инструменты',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.surface.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.surface,
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
        border:
            Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: destructive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodyMedium)
          : null,
      trailing: onTap != null && !destructive
          ? Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap == null
          ? null
          : () {
              HapticsService.tap();
              onTap!();
            },
    );
  }
}
