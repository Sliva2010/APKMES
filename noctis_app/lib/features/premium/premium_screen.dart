// NOCTIS Premium — лендинг с тарифами в фирменном чёрно-белом стиле.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';
import '../../ui/widgets/primary_button.dart';
import 'premium_state.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;
  PremiumPlan _selected = PremiumPlan.annual;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  void _activate() {
    HapticsService.success();
    ref.read(premiumProvider.notifier).activate(_selected);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PremiumState st = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                _RoundButton(
                  icon: Icons.close_rounded,
                  onTap: () => context.pop(),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _shine,
              builder: (BuildContext _, Widget? __) => CustomPaint(
                size: const Size.fromHeight(220),
                painter: _PremiumHeader(
                  primary: MonochromePalette.guard(
                      theme.colorScheme.onSurface),
                  background: MonochromePalette.guard(
                      theme.scaffoldBackgroundColor),
                  shine: _shine.value,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'NOCTIS Premium',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  st.active
                      ? 'Premium активен · спасибо что с нами'
                      : 'Безлимиты, эксклюзивные темы и расширенные инструменты',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ..._features.map(
              (PremiumFeature f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _FeatureRow(feature: f),
              ),
            ),
            const SizedBox(height: 24),
            _PlanCard(
              plan: PremiumPlan.monthly,
              selected: _selected == PremiumPlan.monthly,
              onTap: () {
                HapticsService.selection();
                setState(() => _selected = PremiumPlan.monthly);
              },
            ),
            const SizedBox(height: 12),
            _PlanCard(
              plan: PremiumPlan.annual,
              selected: _selected == PremiumPlan.annual,
              onTap: () {
                HapticsService.selection();
                setState(() => _selected = PremiumPlan.annual);
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: st.active
                  ? 'Premium активен'
                  : _selected == PremiumPlan.annual
                      ? 'Оформить за 990 ₽ / год'
                      : 'Оформить за 99 ₽ / мес',
              onPressed: st.active ? null : _activate,
              icon: Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Можно отменить в любой момент.\nПодписка не продлевается автоматически.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (st.active) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  HapticsService.warning();
                  ref.read(premiumProvider.notifier).cancel();
                },
                child: const Text('Отключить Premium'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
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
              color: theme.colorScheme.outlineVariant, width: 1),
        ),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 18),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});
  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              feature.icon,
              color: theme.colorScheme.surface,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(feature.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool annual = plan == PremiumPlan.annual;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: NoctisDurations.tap,
        curve: NoctisCurves.standard,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: NoctisDurations.tap,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.surface
                      : theme.colorScheme.onSurface,
                  width: 2,
                ),
                color: selected
                    ? theme.colorScheme.surface
                    : Colors.transparent,
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        annual ? 'Годовой' : 'Месячный',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected
                              ? theme.colorScheme.surface
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (annual) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.surface
                                : theme.colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '−18%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.surface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    annual
                        ? '990 ₽ / год · 82 ₽ в месяц'
                        : '99 ₽ / месяц',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.surface.withOpacity(0.85)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumFeature {
  const PremiumFeature(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

const List<PremiumFeature> _features = <PremiumFeature>[
  PremiumFeature(
    Icons.workspace_premium_rounded,
    'Значок Premium',
    'Узнаваемый знак рядом с именем в чатах и профиле.',
  ),
  PremiumFeature(
    Icons.palette_outlined,
    'Эксклюзивные темы',
    'Дополнительные монохромные палитры и оформление.',
  ),
  PremiumFeature(
    Icons.cloud_upload_outlined,
    'Безлимит хранилища',
    'До 4 ГБ на одно вложение и без ограничений по облаку.',
  ),
  PremiumFeature(
    Icons.bolt_rounded,
    'Быстрые загрузки',
    'Приоритетная скорость загрузки и стриминга медиа.',
  ),
  PremiumFeature(
    Icons.translate_rounded,
    'Перевод сообщений',
    'Мгновенный перевод между всеми языками одним тапом.',
  ),
  PremiumFeature(
    Icons.dashboard_customize_outlined,
    'Расширенные инструменты',
    'Премиум-инструменты, виджеты и встроенный редактор.',
  ),
];

class _PremiumHeader extends CustomPainter {
  _PremiumHeader({
    required this.primary,
    required this.background,
    required this.shine,
  });

  final Color primary;
  final Color background;
  final double shine;

  @override
  void paint(Canvas canvas, Size size) {
    // Большой чёрный квадрат с радиусом.
    final RRect card = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(28),
    );
    canvas.drawRRect(card, Paint()..color = primary);

    // Бликующая полоса по диагонали.
    final double t = shine;
    final Path stripe = Path()
      ..moveTo(size.width * (-0.4 + t * 1.4), 0)
      ..lineTo(size.width * (-0.2 + t * 1.4), 0)
      ..lineTo(size.width * (0.4 - t * 1.4), size.height)
      ..lineTo(size.width * (0.2 - t * 1.4), size.height)
      ..close();
    canvas.save();
    canvas.clipRRect(card);
    canvas.drawPath(
      stripe,
      Paint()..color = background.withOpacity(0.05),
    );
    canvas.restore();

    // Большой круг-«монета».
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Paint coinFill = Paint()..color = background;
    canvas.drawCircle(center, 64, coinFill);
    final Paint coinBorder = Paint()
      ..style = PaintingStyle.stroke
      ..color = primary
      ..strokeWidth = 2;
    canvas.drawCircle(center, 64, coinBorder);

    // Иконка короны внутри.
    final Path crown = Path()
      ..moveTo(center.dx - 22, center.dy + 12)
      ..lineTo(center.dx - 16, center.dy - 14)
      ..lineTo(center.dx - 6, center.dy + 2)
      ..lineTo(center.dx, center.dy - 18)
      ..lineTo(center.dx + 6, center.dy + 2)
      ..lineTo(center.dx + 16, center.dy - 14)
      ..lineTo(center.dx + 22, center.dy + 12)
      ..close();
    canvas.drawPath(crown, Paint()..color = primary);

    // Звёздочки вокруг.
    final List<Offset> stars = <Offset>[
      Offset(center.dx - 92, center.dy - 40),
      Offset(center.dx + 96, center.dy - 30),
      Offset(center.dx - 110, center.dy + 50),
      Offset(center.dx + 110, center.dy + 50),
    ];
    final Paint starPaint = Paint()..color = background.withOpacity(0.9);
    for (final Offset s in stars) {
      _drawStar(canvas, s, 6, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    // Простая «искра» — ромб с лучами.
    final Path simple = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.45, c.dy - r * 0.18)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.45, c.dy + r * 0.18)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.45, c.dy + r * 0.18)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.45, c.dy - r * 0.18)
      ..close();
    canvas.drawPath(simple, p);
  }

  @override
  bool shouldRepaint(covariant _PremiumHeader old) =>
      old.shine != shine || old.primary != primary;
}
