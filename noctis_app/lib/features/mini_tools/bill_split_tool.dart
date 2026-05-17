// Mini_Tool: разделение счёта.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';

class BillSplitTool extends StatefulWidget {
  const BillSplitTool({super.key});

  @override
  State<BillSplitTool> createState() => _BillSplitToolState();
}

class _BillSplitToolState extends State<BillSplitTool> {
  double _amount = 1500;
  int _people = 4;
  double _tipPct = 10;
  final TextEditingController _amountCtrl = TextEditingController(text: '1500');

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _totalWithTip => _amount * (1 + _tipPct / 100);
  double get _perPerson => _people == 0 ? 0 : _totalWithTip / _people;

  String _money(double v) =>
      NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Разделить счёт')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            // Большое отображение суммы на человека.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    'НА ЧЕЛОВЕКА',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.surface.withOpacity(0.7),
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: NoctisDurations.tap,
                    child: Text(
                      _money(_perPerson),
                      key: ValueKey<String>(_money(_perPerson)),
                      style: TextStyle(
                        fontFamily: 'NoctisSans',
                        color: MonochromePalette.guard(
                            theme.colorScheme.surface),
                        fontWeight: FontWeight.w700,
                        fontSize: 56,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Итого с чаевыми: ${_money(_totalWithTip)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.surface.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Сумма счёта'),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: theme.textTheme.headlineMedium,
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: '₽',
              ),
              onChanged: (String v) {
                final double parsed =
                    double.tryParse(v.replaceAll(',', '.')) ?? 0;
                setState(() => _amount = parsed);
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle('Людей'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  _CircleIconButton(
                    icon: Icons.remove_rounded,
                    onTap: _people > 1
                        ? () {
                            HapticsService.selection();
                            setState(() => _people--);
                          }
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      _people.toString(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.add_rounded,
                    onTap: _people < 30
                        ? () {
                            HapticsService.selection();
                            setState(() => _people++);
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Чаевые: ${_tipPct.toStringAsFixed(0)}%'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final double pct in <double>[0, 5, 10, 15, 20, 25])
                  _TipChip(
                    label: '${pct.toStringAsFixed(0)}%',
                    selected: (_tipPct - pct).abs() < 0.5,
                    onTap: () {
                      HapticsService.selection();
                      setState(() => _tipPct = pct);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: _tipPct,
              min: 0,
              max: 30,
              divisions: 30,
              label: '${_tipPct.toStringAsFixed(0)}%',
              activeColor: theme.colorScheme.onSurface,
              inactiveColor: theme.colorScheme.outlineVariant,
              onChanged: (double v) => setState(() => _tipPct = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          letterSpacing: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: NoctisDurations.tap,
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: NoctisDurations.tap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? theme.colorScheme.surface
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
