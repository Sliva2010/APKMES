// Создание канала: название, ссылка @username, описание.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/primary_button.dart';
import 'chat_repository.dart';

class ChannelCreateScreen extends ConsumerStatefulWidget {
  const ChannelCreateScreen({super.key});

  @override
  ConsumerState<ChannelCreateScreen> createState() =>
      _ChannelCreateScreenState();
}

class _ChannelCreateScreenState extends ConsumerState<ChannelCreateScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _bio = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _valid {
    if (_title.text.trim().length < 2) return false;
    final String u = _username.text.trim();
    if (u.isNotEmpty && !RegExp(r'^[a-z0-9_]{4,32}$').hasMatch(u)) {
      return false;
    }
    return true;
  }

  void _create() {
    if (!_valid) return;
    HapticsService.success();
    final String title = _title.text.trim();
    final String username = _username.text.trim();
    final String id = username.isNotEmpty
        ? 'c_$username'
        : 'c_${DateTime.now().millisecondsSinceEpoch}';

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
        lastMessage: 'Канал создан',
        lastMessageAt: DateTime.now(),
        unread: 0,
        kind: ChatKind.channel,
        username: username.isEmpty ? null : username,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
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
        title: const Text('Новый канал'),
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
                    Icons.campaign_outlined,
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
                  labelText: 'Название канала',
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
                  labelText: 'Публичная ссылка (необязательно)',
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
                  LengthLimitingTextInputFormatter(255),
                ],
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Создать канал',
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
