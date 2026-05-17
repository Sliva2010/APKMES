// Создание группового чата.
// Поля: название, описание (optional), список участников через add-by-username.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/primary_button.dart';
import 'chat_repository.dart';

class GroupCreateScreen extends ConsumerStatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _member = TextEditingController();
  final List<String> _members = <String>[];

  @override
  void dispose() {
    _title.dispose();
    _bio.dispose();
    _member.dispose();
    super.dispose();
  }

  bool get _valid => _title.text.trim().length >= 2;

  void _addMember() {
    final String m = _member.text.trim();
    if (m.isEmpty) return;
    if (_members.contains(m)) return;
    HapticsService.selection();
    setState(() {
      _members.add(m);
      _member.clear();
    });
  }

  void _create() {
    if (!_valid) return;
    HapticsService.success();
    final String title = _title.text.trim();
    final String id = 'g_${DateTime.now().millisecondsSinceEpoch}';

    final List<ChatSummary> all = ref.read(chatListProvider);
    final ChatSummary saved = all.firstWhere(
      (ChatSummary c) => c.id == 'saved',
      orElse: () => all.first,
    );
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      saved,
      ChatSummary(
        id: id,
        title: title,
        lastMessage: 'Группа создана',
        lastMessageAt: DateTime.now(),
        unread: 0,
        kind: ChatKind.group,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        members: List<String>.unmodifiable(_members),
      ),
      ...all.where((ChatSummary c) => c.id != 'saved'),
    ];
    final Map<String, List<ChatMessage>> messages =
        ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state =
        <String, List<ChatMessage>>{
      ...messages,
      id: <ChatMessage>[],
    };

    context.pop();
    context.push('/chats/$id');
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
        title: const Text('Новая группа'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    size: 36,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _title,
                style: theme.textTheme.titleLarge,
                textCapitalization: TextCapitalization.words,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(64),
                ],
                decoration: const InputDecoration(
                  labelText: 'Название группы',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bio,
                style: theme.textTheme.bodyLarge,
                maxLines: 2,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(140),
                ],
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                ),
              ),
              const SizedBox(height: 24),
              Text('Участники',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  )),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _member,
                      decoration: const InputDecoration(
                        hintText: 'Никнейм или имя',
                        prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                      ),
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_members.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final String m in _members)
                      Chip(
                        label: Text(m),
                        onDeleted: () =>
                            setState(() => _members.remove(m)),
                      ),
                  ],
                ),
              const Spacer(),
              PrimaryButton(
                label: 'Создать группу',
                onPressed: _valid ? _create : null,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
