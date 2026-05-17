// Редактирование профиля: имя, никнейм, био, аватарка.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/animation/haptics_service.dart';
import '../../core/permissions/permission_service.dart';
import '../../ui/widgets/primary_button.dart';
import '../auth/auth_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  String? _avatarPath;
  bool _avatarChanged = false;

  @override
  void initState() {
    super.initState();
    final AuthState s = ref.read(authControllerProvider);
    _name = TextEditingController(text: s.displayName ?? '');
    _username = TextEditingController(text: s.username ?? '');
    _bio = TextEditingController(text: s.bio ?? '');
    _avatarPath = s.avatarPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _valid {
    final String n = _name.text.trim();
    final String u = _username.text.trim();
    if (n.isEmpty || n.length > 64) return false;
    if (!RegExp(r'^[a-z0-9_]{4,32}$').hasMatch(u)) return false;
    return true;
  }

  Future<void> _pickAvatar() async {
    final ThemeData theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                _pickFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Из галереи'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickFromSource(ImageSource.gallery);
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Удалить'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  setState(() {
                    _avatarPath = null;
                    _avatarChanged = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    final bool ok = source == ImageSource.camera
        ? await PermissionService.ensureCamera()
        : await PermissionService.ensurePhotos();
    if (!ok) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? f = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (f != null) {
        setState(() {
          _avatarPath = f.path;
          _avatarChanged = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_valid) return;
    HapticsService.success();
    await ref.read(authControllerProvider.notifier).updateProfile(
          displayName: _name.text.trim(),
          username: _username.text.trim(),
          bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          avatarPath: _avatarChanged ? _avatarPath : null,
          clearAvatar: _avatarChanged && _avatarPath == null,
        );
    if (mounted) context.pop();
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
        title: const Text('Редактировать профиль'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
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
                          image: _avatarPath != null
                              ? DecorationImage(
                                  image: FileImage(File(_avatarPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _avatarPath == null
                            ? Icon(Icons.person_outline_rounded,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant)
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
                          child: Icon(Icons.photo_camera_outlined,
                              size: 18, color: theme.colorScheme.surface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _name,
                style: theme.textTheme.titleLarge,
                textCapitalization: TextCapitalization.words,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(64),
                ],
                decoration: const InputDecoration(labelText: 'Имя'),
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
                  prefixText: '@',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bio,
                style: theme.textTheme.bodyLarge,
                maxLines: 3,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(140),
                ],
                decoration: const InputDecoration(
                  labelText: 'О себе',
                  hintText: 'Несколько слов о вас',
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Сохранить',
                onPressed: _valid ? _save : null,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
