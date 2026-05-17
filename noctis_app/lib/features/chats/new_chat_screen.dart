// Экран создания нового чата.
// На MVP — выбор контакта из локального демо-списка.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import 'chat_repository.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final TextEditingController _query = TextEditingController();

  static const List<_Contact> _contacts = <_Contact>[
    _Contact('Алексей Петров', '@alex_p', '+7 999 123 45 67'),
    _Contact('Мария Соколова', '@mari_s', '+7 999 234 56 78'),
    _Contact('Дмитрий Иванов', '@dmitry_i', '+7 999 345 67 89'),
    _Contact('Екатерина Лебедева', '@kate_l', '+7 999 456 78 90'),
    _Contact('Артём Кузнецов', '@artem_k', '+7 999 567 89 01'),
    _Contact('Ольга Новикова', '@olga_n', '+7 999 678 90 12'),
    _Contact('Виктор Морозов', '@victor_m', '+7 999 789 01 23'),
    _Contact('Полина Орлова', '@polina_o', '+7 999 890 12 34'),
  ];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = _query.text.trim().toLowerCase();
    final List<_Contact> visible = q.isEmpty
        ? _contacts
        : _contacts
            .where((_Contact c) =>
                c.name.toLowerCase().contains(q) ||
                c.username.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Новый чат'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _query,
                decoration: const InputDecoration(
                  hintText: 'Поиск по имени или нику',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: NoctisDurations.list,
                child: ListView.separated(
                  key: ValueKey<String>('list_$q'),
                  itemCount: visible.length,
                  separatorBuilder: (BuildContext _, int __) =>
                      Divider(height: 1, color: theme.colorScheme.outline),
                  itemBuilder: (BuildContext context, int index) {
                    final _Contact c = visible[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          c.initials,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(c.name),
                      subtitle: Text(c.username),
                      trailing: Text(
                        c.phone,
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () {
                        HapticsService.tap();
                        _openOrCreate(context, c);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openOrCreate(BuildContext context, _Contact c) {
    final List<ChatSummary> chats = ref.read(chatListProvider);
    final String id = 'demo-${c.username.replaceAll('@', '')}';
    if (!chats.any((ChatSummary s) => s.id == id)) {
      ref.read(chatListProvider.notifier).state = <ChatSummary>[
        ChatSummary(
          id: id,
          title: c.name,
          lastMessage: 'Чат начат',
          lastMessageAt: DateTime.now(),
          unread: 0,
        ),
        ...chats,
      ];
      final Map<String, List<ChatMessage>> messages =
          ref.read(chatMessagesProvider);
      ref.read(chatMessagesProvider.notifier).state =
          <String, List<ChatMessage>>{
        ...messages,
        id: <ChatMessage>[],
      };
    }
    context.go('/chats/$id');
  }
}

class _Contact {
  const _Contact(this.name, this.username, this.phone);
  final String name;
  final String username;
  final String phone;

  String get initials {
    final List<String> parts = name.split(' ');
    if (parts.length < 2) return parts.first.substring(0, 1);
    return parts[0][0] + parts[1][0];
  }
}
