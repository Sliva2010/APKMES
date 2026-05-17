// Финальный шаг регистрации — отображаемое имя и никнейм.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/primary_button.dart';
import 'auth_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _username = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  bool get _valid {
    final String n = _name.text.trim();
    final String u = _username.text.trim();
    if (n.length < 1 || n.length > 64) return false;
    if (!RegExp(r'^[a-z0-9_]{5,32}$').hasMatch(u)) return false;
    return true;
  }

  Future<void> _finish() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    await HapticsService.selection();
    await ref.read(authControllerProvider.notifier).completeProfile(
          displayName: _name.text.trim(),
          username: _username.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    await HapticsService.success();
    context.go('/chats');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Расскажите о себе',
                  style: theme.textTheme.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Имя видят все ваши собеседники.\n'
                'Никнейм используется для поиска.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _name,
                style: theme.textTheme.titleLarge,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  hintText: 'Например, Анна',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _username,
                style: theme.textTheme.titleLarge,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                  LengthLimitingTextInputFormatter(32),
                ],
                decoration: const InputDecoration(
                  labelText: 'Никнейм',
                  hintText: '@anna_n',
                  prefixText: '@',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Войти в NOCTIS',
                onPressed: _valid ? _finish : null,
                busy: _busy,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
