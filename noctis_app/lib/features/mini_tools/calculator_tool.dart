// Mini_Tool: монохромный калькулятор.
// Простой парсер выражений — поддержка +, -, *, /, ().
import 'package:flutter/material.dart';

import '../../core/animation/haptics_service.dart';

class CalculatorTool extends StatefulWidget {
  const CalculatorTool({super.key});

  @override
  State<CalculatorTool> createState() => _CalculatorToolState();
}

class _CalculatorToolState extends State<CalculatorTool> {
  String _expr = '';
  String _result = '';

  void _press(String s) {
    HapticsService.tap();
    setState(() {
      switch (s) {
        case 'C':
          _expr = '';
          _result = '';
          break;
        case '⌫':
          if (_expr.isNotEmpty) {
            _expr = _expr.substring(0, _expr.length - 1);
          }
          break;
        case '=':
          _result = _evaluate(_expr);
          break;
        default:
          _expr += s;
          _result = _evaluate(_expr);
      }
    });
  }

  String _evaluate(String expr) {
    if (expr.isEmpty) return '';
    try {
      final double v = _Parser(expr).parse();
      if (v.isNaN || v.isInfinite) return '—';
      if (v == v.truncateToDouble()) {
        return v.toInt().toString();
      }
      return v.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<List<String>> rows = <List<String>>[
      <String>['C', '⌫', '(', ')'],
      <String>['7', '8', '9', '/'],
      <String>['4', '5', '6', '*'],
      <String>['1', '2', '3', '-'],
      <String>['0', '.', '=', '+'],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                alignment: Alignment.bottomRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      _expr.isEmpty ? '0' : _expr,
                      style: theme.textTheme.displayMedium,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                children: <Widget>[
                  for (final List<String> row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          for (final String s in row) ...<Widget>[
                            Expanded(
                              child: _CalcButton(
                                label: s,
                                onTap: () => _press(s),
                                emphasis: s == '=' || s == 'C' || s == '⌫',
                              ),
                            ),
                            if (s != row.last) const SizedBox(width: 8),
                          ],
                        ],
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

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.onTap,
    this.emphasis = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: emphasis
              ? theme.colorScheme.onSurface
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(
            color: emphasis
                ? theme.colorScheme.surface
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Простейший рекурсивный парсер выражений.
class _Parser {
  _Parser(this._src);

  final String _src;
  int _i = 0;

  double parse() {
    final double v = _expr();
    if (_i != _src.length) throw FormatException('extra at $_i');
    return v;
  }

  double _expr() {
    double v = _term();
    while (_i < _src.length && (_src[_i] == '+' || _src[_i] == '-')) {
      final String op = _src[_i++];
      final double r = _term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _term() {
    double v = _factor();
    while (_i < _src.length && (_src[_i] == '*' || _src[_i] == '/')) {
      final String op = _src[_i++];
      final double r = _factor();
      v = op == '*' ? v * r : v / r;
    }
    return v;
  }

  double _factor() {
    if (_i < _src.length && _src[_i] == '-') {
      _i++;
      return -_factor();
    }
    if (_i < _src.length && _src[_i] == '(') {
      _i++;
      final double v = _expr();
      if (_i >= _src.length || _src[_i] != ')') {
        throw const FormatException('unbalanced paren');
      }
      _i++;
      return v;
    }
    return _number();
  }

  double _number() {
    final int start = _i;
    while (_i < _src.length &&
        (RegExp(r'[0-9.]').hasMatch(_src[_i]))) {
      _i++;
    }
    if (start == _i) throw const FormatException('expected number');
    return double.parse(_src.substring(start, _i));
  }
}
