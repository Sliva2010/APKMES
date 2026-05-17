// Выбор языка интерфейса.
// Демо: список языков, активный — Русский.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/animation/haptics_service.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selected = 'ru';

  static const List<MapEntry<String, String>> _langs =
      <MapEntry<String, String>>[
    MapEntry<String, String>('ru', 'Русский'),
    MapEntry<String, String>('en', 'English'),
    MapEntry<String, String>('uk', 'Українська'),
    MapEntry<String, String>('be', 'Беларуская'),
    MapEntry<String, String>('kk', 'Қазақша'),
    MapEntry<String, String>('uz', 'Oʻzbekcha'),
    MapEntry<String, String>('de', 'Deutsch'),
    MapEntry<String, String>('fr', 'Français'),
    MapEntry<String, String>('es', 'Español'),
    MapEntry<String, String>('it', 'Italiano'),
    MapEntry<String, String>('pt', 'Português'),
    MapEntry<String, String>('zh', '中文'),
    MapEntry<String, String>('ja', '日本語'),
    MapEntry<String, String>('ko', '한국어'),
    MapEntry<String, String>('tr', 'Türkçe'),
    MapEntry<String, String>('ar', 'العربية'),
  ];

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      setState(() => _selected = p.getString('noctis.lang') ?? 'ru');
    } catch (_) {}
  }

  Future<void> _persist(String code) async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('noctis.lang', code);
    } catch (_) {}
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
        title: const Text('Язык'),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _langs.length,
          separatorBuilder: (BuildContext _, int __) =>
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
          itemBuilder: (BuildContext context, int index) {
            final MapEntry<String, String> e = _langs[index];
            final bool active = e.key == _selected;
            return ListTile(
              leading: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  e.key.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(e.value),
              trailing: active
                  ? Icon(Icons.check_rounded,
                      color: theme.colorScheme.onSurface)
                  : null,
              onTap: () {
                HapticsService.selection();
                setState(() => _selected = e.key);
                _persist(e.key);
              },
            );
          },
        ),
      ),
    );
  }
}
