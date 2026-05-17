// Безопасность: облачный пароль, App Lock, биометрия, активные сессии.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import 'security_state.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final SecurityState state = ref.watch(securityProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Безопасность'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _Card(
              children: <Widget>[
                _Switch(
                  title: 'App Lock',
                  subtitle: 'Запрос кода или биометрии при открытии',
                  value: state.appLock,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    ref.read(securityProvider.notifier).setAppLock(v);
                  },
                ),
                const Divider(height: 1),
                _Switch(
                  title: 'Биометрия',
                  subtitle: 'Face ID / отпечаток пальца как быстрый вход',
                  value: state.biometric,
                  enabled: state.appLock,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    ref.read(securityProvider.notifier).setBiometric(v);
                  },
                ),
                const Divider(height: 1),
                _Switch(
                  title: 'Скрывать превью',
                  subtitle: 'Не показывать текст в уведомлениях',
                  value: state.hidePreview,
                  onChanged: (bool v) {
                    HapticsService.selection();
                    ref.read(securityProvider.notifier).setHidePreview(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Card(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Облачный пароль (2FA)'),
                  subtitle: Text(
                    state.cloudPasswordSet ? 'Включён' : 'Не настроен',
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticsService.tap();
                    _showCloudPasswordSheet(context, ref, state);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_other_rounded),
                  title: const Text('Активные сессии'),
                  subtitle: Text('${state.sessions.length} устройства'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticsService.tap();
                    context.push('/settings/sessions');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Приватность'),
                  subtitle: const Text('Кто видит ваш номер, статус и аватар'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    HapticsService.tap();
                    context.push('/settings/privacy');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Все ключи шифрования хранятся локально\nи никогда не покидают устройство',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloudPasswordSheet(
      BuildContext context, WidgetRef ref, SecurityState state) {
    final TextEditingController controller = TextEditingController();
    bool obscure = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext _, StateSetter setSheet) {
              final ThemeData theme = Theme.of(sheetCtx);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    state.cloudPasswordSet
                        ? 'Облачный пароль'
                        : 'Установить пароль',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Запрашивается после OTP-кода. От 8 до 64 символов.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Пароль',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setSheet(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final String v = controller.text.trim();
                      if (v.length >= 8 && v.length <= 64) {
                        ref
                            .read(securityProvider.notifier)
                            .setCloudPassword(true);
                        Navigator.pop(sheetCtx);
                        HapticsService.success();
                      } else {
                        HapticsService.error();
                      }
                    },
                    child: Text(state.cloudPasswordSet
                        ? 'Обновить'
                        : 'Сохранить'),
                  ),
                  if (state.cloudPasswordSet) ...<Widget>[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(securityProvider.notifier)
                            .setCloudPassword(false);
                        Navigator.pop(sheetCtx);
                      },
                      child: const Text('Отключить'),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
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

class _Switch extends StatelessWidget {
  const _Switch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: theme.colorScheme.onSurface,
      ),
    );
  }
}
