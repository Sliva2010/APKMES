// Welcome — финальная страница входа после онбординга.
// Премиальная вёрстка: лого, типографичный заголовок, карточки преимуществ,
// две первичные кнопки.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';
import '../../ui/widgets/noctis_logo.dart';
import '../../ui/widgets/primary_button.dart';
import 'welcome_background.dart';

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
    _fadeIn = CurvedAnimation(parent: _intro, curve: NoctisCurves.entrance);
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
      body: WelcomeBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slide,
                    child: const Center(
                      child: NoctisLogo(size: 96, label: false),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Тишина и слово',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayMedium?.copyWith(
                            height: 1.05,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Премиальный мессенджер в строгой\nчёрно-белой эстетике.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slide,
                    child: const _Highlights(),
                  ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _fadeIn,
                  child: PrimaryButton(
                    label: 'Создать аккаунт',
                    onPressed: () {
                      HapticsService.tap();
                      context.push('/register');
                    },
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Продолжая, вы соглашаетесь с условиями\nи политикой конфиденциальности.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MonochromePalette.guard(
                      theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: _HighlightCard(
            icon: Icons.shield_outlined,
            title: 'E2EE',
            subtitle: 'Сквозное\nшифрование',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _HighlightCard(
            icon: Icons.bolt_rounded,
            title: '60 fps',
            subtitle: 'Премиальные\nанимации',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _HighlightCard(
            icon: Icons.timelapse_rounded,
            title: 'TTL',
            subtitle: 'Исчезающие\nсообщения',
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

