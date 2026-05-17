// Палитра встроенных мини-инструментов NOCTIS.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';

class MiniToolsScreen extends StatelessWidget {
  const MiniToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_Tool> tools = <_Tool>[
      _Tool('Калькулятор', Icons.calculate_outlined, '/tools/calculator'),
      _Tool('Таймер', Icons.timer_outlined, '/tools/timer'),
      _Tool('QR-код', Icons.qr_code_2_rounded, '/tools/qr'),
      _Tool('Переводчик', Icons.translate_rounded, '/tools/translator'),
      _Tool('Разделить счёт', Icons.account_balance_wallet_outlined,
          '/tools/bill'),
      _Tool('Конвертер валют', Icons.currency_exchange_rounded, null),
      _Tool('Опрос', Icons.poll_outlined, null),
      _Tool('Заметка', Icons.sticky_note_2_outlined, null),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Инструменты'),
      ),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: <Widget>[
            for (final _Tool t in tools)
              _ToolTile(
                tool: t,
                onTap: () {
                  HapticsService.tap();
                  if (t.route != null) {
                    context.push(t.route!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Скоро: ${t.title}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Tool {
  const _Tool(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String? route;
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool, required this.onTap});
  final _Tool tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  tool.icon,
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                tool.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
