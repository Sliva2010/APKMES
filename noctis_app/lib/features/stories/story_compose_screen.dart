// Создание новой истории — текст + опциональная картинка.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/animation/haptics_service.dart';
import '../../core/permissions/permission_service.dart';
import '../../ui/widgets/primary_button.dart';
import 'stories_repository.dart';

class StoryComposeScreen extends ConsumerStatefulWidget {
  const StoryComposeScreen({super.key});

  @override
  ConsumerState<StoryComposeScreen> createState() =>
      _StoryComposeScreenState();
}

class _StoryComposeScreenState extends ConsumerState<StoryComposeScreen> {
  final TextEditingController _text = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final bool ok = source == ImageSource.camera
        ? await PermissionService.ensureCamera()
        : await PermissionService.ensurePhotos();
    if (!ok) return;
    final ImagePicker p = ImagePicker();
    try {
      final XFile? f = await p.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 90,
      );
      if (f != null) {
        setState(() => _imagePath = f.path);
      }
    } catch (_) {}
  }

  void _publish() {
    if (_text.text.trim().isEmpty && _imagePath == null) return;
    HapticsService.success();
    ref.read(storiesProvider.notifier).addMyStory(
          text: _text.text.trim(),
          imagePath: _imagePath,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Новая история'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  final ThemeData theme = Theme.of(context);
                  await showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: theme.colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (BuildContext sheetCtx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.photo_camera_outlined),
                            title: const Text('Сделать фото'),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library_outlined),
                            title: const Text('Из галереи'),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                          if (_imagePath != null)
                            ListTile(
                              leading:
                                  const Icon(Icons.delete_outline_rounded),
                              title: const Text('Удалить картинку'),
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                setState(() => _imagePath = null);
                              },
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                    image: _imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imagePath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.image_outlined,
                              size: 36,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            Text('Добавить картинку (необязательно)',
                                style: theme.textTheme.bodyMedium),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _text,
                maxLines: 5,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(280),
                ],
                style: theme.textTheme.titleMedium,
                decoration: const InputDecoration(
                  labelText: 'Текст',
                  hintText: 'Поделитесь моментом',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Опубликовать',
                onPressed:
                    (_text.text.trim().isEmpty && _imagePath == null)
                        ? null
                        : _publish,
                icon: Icons.upload_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
