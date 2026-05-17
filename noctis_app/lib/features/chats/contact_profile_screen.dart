// Профиль собеседника / чата.
// Аватар (можно листать в галерею собеседника), действия,
// блок / mute / архив / уведомления.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../calls/call_screen.dart';
import 'chat_repository.dart';

class ContactProfileScreen extends ConsumerStatefulWidget {
  const ContactProfileScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ContactProfileScreen> createState() =>
      _ContactProfileScreenState();
}

class _ContactProfileScreenState
    extends ConsumerState<ContactProfileScreen> {
  final PageController _avatarPager = PageController();

  @override
  void dispose() {
    _avatarPager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ChatSummary chat = ref.watch(chatListProvider).firstWhere(
          (ChatSummary c) => c.id == widget.chatId,
          orElse: () => ChatSummary(
            id: widget.chatId,
            title: 'Чат',
            lastMessage: '',
            lastMessageAt: DateTime.now(),
            unread: 0,
          ),
        );

    final List<String?> avatars = <String?>[chat.avatarPath];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 320,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 16,
                        top: 8,
                        child: IconButton(
                          icon: const Icon(
                              Icons.arrow_back_ios_new_rounded, size: 18),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 156,
                              height: 156,
                              child: PageView.builder(
                                controller: _avatarPager,
                                itemCount: avatars.length,
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  final String? path = avatars[index];
                                  return Center(
                                    child: Container(
                                      width: 132,
                                      height: 132,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSurface,
                                        shape: BoxShape.circle,
                                        image: path != null &&
                                                File(path).existsSync()
                                            ? DecorationImage(
                                                image: FileImage(File(path)),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: path == null
                                          ? Text(
                                              chat.initials,
                                              style: TextStyle(
                                                fontFamily: 'NoctisSans',
                                                fontSize: 56,
                                                fontWeight: FontWeight.w700,
                                                color: theme
                                                    .colorScheme.surface,
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              chat.title,
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat.isChannel
                                  ? 'канал'
                                  : chat.isGroup
                                      ? '${chat.members.length + 1} участников'
                                      : chat.username != null
                                          ? '@${chat.username}'
                                          : 'недавно в сети',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Сообщение',
                      onTap: () => context.pop(),
                    ),
                    if (!chat.isChannel)
                      _ActionButton(
                        icon: Icons.call_outlined,
                        label: 'Звонок',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext _) => CallScreen(
                              contactName: chat.title,
                              contactInitials: chat.initials,
                            ),
                          ),
                        ),
                      ),
                    if (!chat.isChannel)
                      _ActionButton(
                        icon: Icons.videocam_outlined,
                        label: 'Видео',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext _) => CallScreen(
                              contactName: chat.title,
                              contactInitials: chat.initials,
                              video: true,
                            ),
                          ),
                        ),
                      ),
                    _ActionButton(
                      icon: chat.muted
                          ? Icons.notifications_off_outlined
                          : Icons.notifications_none_rounded,
                      label: chat.muted ? 'Включить' : 'Без звука',
                      onTap: () => _toggleMute(chat),
                    ),
                  ],
                ),
              ),
            ),
            if (chat.bio != null && chat.bio!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _Card(
                    children: <Widget>[
                      _InfoRow(
                        icon: Icons.info_outline_rounded,
                        label: 'О себе',
                        value: chat.bio!,
                      ),
                    ],
                  ),
                ),
              ),
            if (chat.username != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _Card(
                    children: <Widget>[
                      _InfoRow(
                        icon: Icons.alternate_email_rounded,
                        label: 'Никнейм',
                        value: '@${chat.username}',
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _Card(
                  children: <Widget>[
                    SwitchListTile(
                      secondary:
                          const Icon(Icons.notifications_off_outlined),
                      title: const Text('Отключить уведомления'),
                      value: chat.muted,
                      onChanged: (_) => _toggleMute(chat),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(chat.archived
                          ? Icons.unarchive_rounded
                          : Icons.archive_outlined),
                      title: const Text('В архиве'),
                      value: chat.archived,
                      onChanged: (_) => _toggleArchive(chat),
                    ),
                    if (!chat.isChannel && !chat.isGroup && !chat.isSaved) ...<Widget>[
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(chat.blocked
                            ? Icons.lock_open_rounded
                            : Icons.block_rounded),
                        title: Text(chat.blocked
                            ? 'Разблокировать пользователя'
                            : 'Заблокировать пользователя'),
                        value: chat.blocked,
                        onChanged: (_) => _toggleBlock(chat),
                      ),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: const Text('Удалить чат'),
                      onTap: () => _deleteChat(chat),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMute(ChatSummary chat) {
    HapticsService.selection();
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      for (final ChatSummary x in ref.read(chatListProvider))
        if (x.id == chat.id) x.copyWith(muted: !x.muted) else x,
    ];
  }

  void _toggleArchive(ChatSummary chat) {
    HapticsService.warning();
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      for (final ChatSummary x in ref.read(chatListProvider))
        if (x.id == chat.id) x.copyWith(archived: !x.archived) else x,
    ];
  }

  void _toggleBlock(ChatSummary chat) {
    HapticsService.warning();
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      for (final ChatSummary x in ref.read(chatListProvider))
        if (x.id == chat.id) x.copyWith(blocked: !x.blocked) else x,
    ];
  }

  void _deleteChat(ChatSummary chat) {
    HapticsService.warning();
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      for (final ChatSummary x in ref.read(chatListProvider))
        if (x.id != chat.id) x,
    ];
    final Map<String, List<ChatMessage>> map =
        ref.read(chatMessagesProvider);
    final Map<String, List<ChatMessage>> next =
        Map<String, List<ChatMessage>>.from(map)..remove(chat.id);
    ref.read(chatMessagesProvider.notifier).state = next;
    if (mounted) {
      context.go('/chats');
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticsService.tap();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
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
        border:
            Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(value, style: theme.textTheme.titleMedium),
      subtitle: Text(label, style: theme.textTheme.bodySmall),
    );
  }
}
