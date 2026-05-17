// Архив чатов: список заархивированных чатов и быстрые действия.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/animation/haptics_service.dart';
import '../chats/chat_avatar.dart';
import '../chats/chat_repository.dart';

class ArchivedChatsScreen extends ConsumerWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<ChatSummary> archived = ref
        .watch(chatListProvider)
        .where((ChatSummary c) => c.archived)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Архив'),
      ),
      body: SafeArea(
        child: archived.isEmpty
            ? _Empty()
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: archived.length,
                separatorBuilder: (BuildContext _, int __) => Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final ChatSummary chat = archived[index];
                  return ListTile(
                    leading: ChatAvatar(chat: chat, size: 44),
                    title: Text(chat.title),
                    subtitle: Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      DateFormat.Hm().format(chat.lastMessageAt),
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () {
                      HapticsService.tap();
                      context.push('/chats/${chat.id}');
                    },
                    onLongPress: () => _showActions(context, ref, chat),
                  );
                },
              ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, ChatSummary chat) {
    HapticsService.warning();
    final ThemeData theme = Theme.of(context);
    showModalBottomSheet<void>(
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
              ListTile(
                leading: const Icon(Icons.unarchive_rounded),
                title: const Text('Вернуть из архива'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ref.read(chatListProvider.notifier).state = <ChatSummary>[
                    for (final ChatSummary x in ref.read(chatListProvider))
                      if (x.id == chat.id)
                        x.copyWith(archived: false)
                      else
                        x,
                  ];
                },
              ),
              ListTile(
                leading: Icon(
                  chat.muted
                      ? Icons.notifications_outlined
                      : Icons.notifications_off_outlined,
                ),
                title:
                    Text(chat.muted ? 'Включить уведомления' : 'Отключить уведомления'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ref.read(chatListProvider.notifier).state = <ChatSummary>[
                    for (final ChatSummary x in ref.read(chatListProvider))
                      if (x.id == chat.id)
                        x.copyWith(muted: !x.muted)
                      else
                        x,
                  ];
                },
              ),
              ListTile(
                leading: Icon(
                  chat.blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                ),
                title: Text(
                  chat.blocked ? 'Разблокировать' : 'Заблокировать',
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ref.read(chatListProvider.notifier).state = <ChatSummary>[
                    for (final ChatSummary x in ref.read(chatListProvider))
                      if (x.id == chat.id)
                        x.copyWith(blocked: !x.blocked)
                      else
                        x,
                  ];
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Удалить чат'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ref.read(chatListProvider.notifier).state = <ChatSummary>[
                    for (final ChatSummary x in ref.read(chatListProvider))
                      if (x.id != chat.id) x,
                  ];
                  final Map<String, List<ChatMessage>> map =
                      ref.read(chatMessagesProvider);
                  final Map<String, List<ChatMessage>> next =
                      Map<String, List<ChatMessage>>.from(map)
                        ..remove(chat.id);
                  ref.read(chatMessagesProvider.notifier).state = next;
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.archive_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Архив пуст', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Свайп влево по чату — поместить его в архив.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
