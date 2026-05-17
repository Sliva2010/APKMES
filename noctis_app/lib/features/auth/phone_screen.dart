// Экран ввода номера телефона с премиальным дизайном.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/primary_button.dart';
import 'auth_controller.dart';
import 'welcome_background.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final TextEditingController _controller = TextEditingController(text: '+7');
  final FocusNode _focusNode = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _valid {
    final RegExp e164 = RegExp(r'^\+[1-9]\d{7,14}$');
    return e164.hasMatch(_controller.text.trim());
  }

  Future<void> _continue() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    await HapticsService.selection();
    await ref
        .read(authControllerProvider.notifier)
        .requestCode(_controller.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    context.push('/otp', extra: <String, dynamic>{'phone': _controller.text});
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: WelcomeBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _BackButton(onTap: () => context.pop()),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: theme.colorScheme.surface,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ваш номер',
                  style: theme.textTheme.displayMedium?.copyWith(
                    height: 1.05,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Мы отправим SMS с одноразовым\nкодом подтверждения.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.phone,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[+\d\s]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  decoration: const InputDecoration(
                    hintText: '+7 999 000 00 00',
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _continue(),
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Номер не виден другим пользователям, если вы не разрешите.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Получить код',
                  onPressed: _valid ? _continue : null,
                  busy: _busy,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
