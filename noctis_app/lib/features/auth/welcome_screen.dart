// Premium welcome-экран — первый штрих NOCTIS.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../ui/widgets/noctis_logo.dart';
import '../../ui/widgets/primary_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeIn = CurvedAnimation(
      parent: _intro,
      curve: NoctisCurves.entrance,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(_fadeIn);
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slide,
                  child: const Center(child: NoctisLogo(size: 110)),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Тишина и слово',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Премиальный мессенджер для тех, кто ценит\nлёгкость, скорость и приватность.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fadeIn,
                child: PrimaryButton(
                  label: 'Создать аккаунт',
                  onPressed: () => context.push('/phone'),
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _fadeIn,
                child: TextButton(
                  onPressed: () => context.push('/phone'),
                  child: Text(
                    'У меня уже есть аккаунт',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Продолжая, вы соглашаетесь с условиями использования\nи политикой конфиденциальности.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
