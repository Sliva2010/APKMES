// Экран ввода 6-значного кода подтверждения.
// Шесть отдельных ячеек с автопереходом и мгновенной верификацией.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';
import 'auth_controller.dart';

class OtpInputScreen extends ConsumerStatefulWidget {
  const OtpInputScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpInputScreen> createState() => _OtpInputScreenState();
}

class _OtpInputScreenState extends ConsumerState<OtpInputScreen> {
  static const int _length = 6;
  final List<TextEditingController> _controllers = List<TextEditingController>
      .generate(_length, (_) => TextEditingController());
  final List<FocusNode> _nodes =
      List<FocusNode>.generate(_length, (_) => FocusNode());

  bool _busy = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((TextEditingController c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != _length || _busy) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    await HapticsService.selection();
    final bool ok =
        await ref.read(authControllerProvider.notifier).verifyCode(_code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      await HapticsService.error();
      setState(() => _errorText = 'Код не подошёл. Попробуйте ещё раз.');
      for (final TextEditingController c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      return;
    }
    await HapticsService.success();
    context.go('/profile-setup');
  }

  void _onChange(int index, String value) {
    setState(() => _errorText = null);
    if (value.isEmpty) {
      if (index > 0) _nodes[index - 1].requestFocus();
      return;
    }
    if (index < _length - 1) {
      _nodes[index + 1].requestFocus();
    } else {
      _nodes[index].unfocus();
      _verify();
    }
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
              Text('Подтвердите номер',
                  style: theme.textTheme.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Мы отправили 6-значный код на ${widget.phone}.\n'
                'Для демо введите 000000.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (int i = 0; i < _length; i++)
                    _OtpCell(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      onChanged: (String v) => _onChange(i, v),
                      hasError: _errorText != null,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: NoctisDurations.tap,
                child: _errorText == null
                    ? const SizedBox(height: 20)
                    : Text(
                        _errorText!,
                        key: ValueKey<String>(_errorText!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
              ),
              const Spacer(),
              if (_busy)
                Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onSurface,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .requestCode(widget.phone);
                  await HapticsService.tap();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: theme.colorScheme.surface,
                      content: Text(
                        'Код отправлен повторно',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Отправить код снова',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool focused = focusNode.hasFocus;
    final Color border = hasError
        ? theme.colorScheme.onSurface
        : focused
            ? theme.colorScheme.onSurface
            : theme.colorScheme.outlineVariant;
    return AnimatedContainer(
      duration: NoctisDurations.tap,
      curve: NoctisCurves.standard,
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MonochromePalette.guard(border),
          width: focused || hasError ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        cursorColor: theme.colorScheme.onSurface,
        style: theme.textTheme.headlineMedium,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          fillColor: Colors.transparent,
          filled: false,
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: onChanged,
      ),
    );
  }
}
