// Экран ввода номера телефона.
// Чистая премиальная вёрстка, мгновенная валидация формата.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/primary_button.dart';
import 'auth_controller.dart';

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Text('Ваш номер', style: theme.textTheme.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Мы отправим код подтверждения на этот номер.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                style: theme.textTheme.headlineMedium,
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
              PrimaryButton(
                label: 'Получить код',
                onPressed: _valid ? _continue : null,
                busy: _busy,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
