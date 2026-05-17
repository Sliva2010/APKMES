// Память и данные: суммарное использование, очистка кэша.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/animation/haptics_service.dart';

class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  int? _cacheBytes;
  int? _docsBytes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<int> _dirSize(Directory d) async {
    int total = 0;
    try {
      if (!await d.exists()) return 0;
      await for (final FileSystemEntity f in d.list(recursive: true, followLinks: false)) {
        if (f is File) {
          try {
            total += await f.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  Future<void> _measure() async {
    setState(() => _busy = true);
    try {
      final Directory cache = await getTemporaryDirectory();
      final Directory docs = await getApplicationDocumentsDirectory();
      final int c = await _dirSize(cache);
      final int d = await _dirSize(docs);
      if (mounted) {
        setState(() {
          _cacheBytes = c;
          _docsBytes = d;
          _busy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearCache() async {
    HapticsService.warning();
    setState(() => _busy = true);
    try {
      final Directory cache = await getTemporaryDirectory();
      if (await cache.exists()) {
        for (final FileSystemEntity f in cache.listSync()) {
          try {
            if (f is File) {
              f.deleteSync();
            } else if (f is Directory) {
              f.deleteSync(recursive: true);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    await _measure();
  }

  String _format(int? bytes) {
    if (bytes == null) return '...';
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} ГБ';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int total = (_cacheBytes ?? 0) + (_docsBytes ?? 0);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Память и данные'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Использовано',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.surface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _format(total),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Card(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Документы'),
                  trailing: Text(_format(_docsBytes)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cached_rounded),
                  title: const Text('Кэш'),
                  trailing: Text(_format(_cacheBytes)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Очистить кэш'),
                  enabled: !_busy && (_cacheBytes ?? 0) > 0,
                  onTap: _busy ? null : _clearCache,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }
}
