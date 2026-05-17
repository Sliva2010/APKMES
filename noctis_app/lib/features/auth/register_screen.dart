// Регистрация в NOCTIS без телефона.
// Имя + никнейм + опциональная аватарка из галереи или камеры.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/animation/haptics_service.dart';
import '../../core/permissions/permission_service.dart';
import '../../ui/widgets/primary_button.dart';
import 'auth_controller.dart';
import 'welcome_background.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _username = TextEditingController();
  String? _avatarPath;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  bool get _valid {
    final String n = _name.text.trim();
    final String u = _username.text.trim();
    if (n.length < 1 || n.length > 64) return false;
    if (!RegExp(r'^[a-z0-9_]{4,32}$').hasMatch(u)) return false;
    return true;
  }

  Future<void> _pickAvatar() async {
    HapticsService.tap();
    final ThemeData theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Сделать фото'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _pickFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Из галереи'),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _pickFromSource(ImageSource.gallery);
                },
              ),
              if (_avatarPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Удалить'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    setState(() => _avatarPath = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    final bool ok = source == ImageSource.camera
        ? await PermissionService.ensureCamera()
        : await PermissionService.ensurePhotos();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет разрешения')),
        );
      }
      return;
    }
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _avatarPath = file.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось выбрать изображение')),
        );
      }
    }
  }

  Future<void> _finish() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    await HapticsService.selection();
    await ref.read(authControllerProvider.notifier).register(
          displayName: _name.text.trim(),
          username: _username.text.trim(),
          avatarPath: _avatarPath,
        );
    // Сразу попросим разрешение на уведомления — для звонков и сообщений.
    await PermissionService.ensureNotifications();
    if (!mounted) return;
    setState(() => _busy = false);
    await HapticsService.success();
    context.go('/chats');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: WelcomeBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Создайте аккаунт',
                    style: theme.textTheme.displayMedium),
                const SizedBox(height: 12),
                Text(
                  'Имя и никнейм увидят ваши собеседники.\n'
                  'Аватарку можно поставить позже.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: _AvatarPicker(path: _avatarPath),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _name,
                  style: theme.textTheme.titleLarge,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    hintText: 'Например, Анна',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _username,
                  style: theme.textTheme.titleLarge,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                    LengthLimitingTextInputFormatter(32),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Никнейм',
                    hintText: 'anna_n',
                    prefixText: '@',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Войти в NOCTIS',
                  onPressed: _valid ? _finish : null,
                  busy: _busy,
                ),
                const SizedBox(height: 12),
                Text(
                  'Никнейм должен быть от 4 до 32 символов:\n'
                  'латинские буквы, цифры и подчёркивание.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
            image: path != null
                ? DecorationImage(
                    image: FileImage(File(path!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: path == null
              ? Icon(
                  Icons.person_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 3,
              ),
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 18,
              color: theme.colorScheme.surface,
            ),
          ),
        ),
      ],
    );
  }
}
