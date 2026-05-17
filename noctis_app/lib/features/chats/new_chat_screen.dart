// Новый чат — создание контакта по имени и нику.
// Без захардкоженных контактов: пользователь вводит имя/ник вручную.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/primary_button.dart';
import 'chat_repository.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _username = TextEditingController();

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
    if (u.isEmpty) return true;
    return RegExp(r'^[a-z0-9_]{3,32}$').hasMatch(u);
  }

  void _create() {
    if (!_valid) return;
    HapticsService.success();
    final String name = _name.text.trim();
    final String username = _username.text.trim();
    final String id = username.isNotEmpty
        ? 'u_$username'
        : 'u_${name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}_${DateTime.now().millisecondsSinceEpoch}';

    final List<ChatSummary> chats = ref.read(chatListProvider);
    if (!chats.any((ChatSummary c) => c.id == id)) {
      ref.read(chatListProvider.notifier).state = <ChatSummary>[
        chats.firstWhere((ChatSummary c) => c.id == 'saved',
            orElse: () => chats.first),
        ChatSummary(
          id: id,
          title: name,
          lastMessage: 'Чат начат',
          lastMessageAt: DateTime.now(),
          unread: 0,
          username: username.isEmpty ? null : username,
        ),
        ...chats.where((ChatSummary c) => c.id != 'saved'),
      ];
      final Map<String, List<ChatMessage>> messages =
          ref.read(chatMessagesProvider);
      ref.read(chatMessagesProvider.notifier).state =
          <String, List<ChatMessage>>{
        ...messages,
        id: <ChatMessage>[],
      };
    }
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
        title: const Text('Новый чат'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Text(
                'Введите имя контакта или его никнейм для создания личной переписки.',
                style: theme.textTheme.bodyMedium,
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
                  labelText: 'Никнейм (необязательно)',
                  prefixText: '@',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Создать чат',
                onPressed: _valid ? _create : null,
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
