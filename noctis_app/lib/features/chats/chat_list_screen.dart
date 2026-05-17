// Главный экран — список чатов с swipe-действиями (архив, mute, pin)
// и быстрым поиском по заголовку прямо в списке.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../stories/stories_strip.dart';
import 'chat_avatar.dart';
import 'chat_repository.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _query = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    HapticsService.tap();
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) _query.clear();
    });
  }

  void _openComposeMenu() {
    HapticsService.tap();
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
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Новый чат'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push('/chats/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Новая группа'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push('/chats/group');
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Новый канал'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push('/chats/channel');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ChatSummary> all = ref.watch(chatListProvider);
    final String q = _query.text.trim().toLowerCase();
    final List<ChatSummary> visible = all
        .where((ChatSummary c) => !c.archived)
        .where((ChatSummary c) =>
            q.isEmpty ||
            c.title.toLowerCase().contains(q) ||
            (c.username?.toLowerCase().contains(q) ?? false) ||
            c.lastMessage.toLowerCase().contains(q))
        .toList();
    final List<ChatSummary> chats = <ChatSummary>[
      ...visible.where((ChatSummary c) => c.pinned),
      ...visible.where((ChatSummary c) => !c.pinned),
    ];
    final int archivedCount =
        all.where((ChatSummary c) => c.archived).length;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _searchOpen
            ? TextField(
                controller: _query,
                autofocus: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: 'Поиск',
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('NOCTIS'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: _toggleSearch,
          ),
          if (!_searchOpen)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _openComposeMenu,
            ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            if (!_searchOpen)
              const SliverToBoxAdapter(child: StoriesStrip()),
            if (archivedCount > 0 && !_searchOpen)
              SliverToBoxAdapter(
                child: _ArchivedTile(
                  count: archivedCount,
                  onTap: () => context.push('/chats/archived'),
                ),
              ),
            if (!_searchOpen)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Чаты',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (chats.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(searching: q.isNotEmpty),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverList.separated(
                  itemCount: chats.length,
                  separatorBuilder: (BuildContext _, int __) =>
                      const SizedBox(height: 2),
                  itemBuilder: (BuildContext context, int index) {
                    final ChatSummary chat = chats[index];
                    return _ChatTile(
                      chat: chat,
                      onTap: () {
                        HapticsService.tap();
                        context.push('/chats/${chat.id}');
                      },
                      onArchive: () => _toggleArchive(ref, chat),
                      onMute: () => _toggleMute(ref, chat),
                      onPin: () => _togglePin(ref, chat),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _searchOpen
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: FloatingActionButton(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                onPressed: _openComposeMenu,
                child: const Icon(Icons.edit_rounded),
              ),
            ),
    );
  }

  void _toggleArchive(WidgetRef ref, ChatSummary c) {
    HapticsService.warning();
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      for (final ChatSummary x in ref.read(chatListProvider))
        if (x.id == c.id) x.copyWith(archived: !x.archived) else x,
    ];
  }

  void _toggleMute(WidgetRef ref, ChatSummary c) {
    HapticsService.selection();
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      for (final ChatSummary x in ref.read(chatListProvider))
        if (x.id == c.id) x.copyWith(muted: !x.muted) else x,
    ];
  }

  void _togglePin(WidgetRef ref, ChatSummary c) {
    HapticsService.selection();
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      for (final ChatSummary x in ref.read(chatListProvider))
        if (x.id == c.id) x.copyWith(pinned: !x.pinned) else x,
    ];
  }
}

class _ChatTile extends StatefulWidget {
  const _ChatTile({
    required this.chat,
    required this.onTap,
    required this.onArchive,
    required this.onMute,
    required this.onPin,
  });

  final ChatSummary chat;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onMute;
  final VoidCallback onPin;

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Dismissible(
      key: ValueKey<String>(widget.chat.id),
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        icon: widget.chat.pinned
            ? Icons.push_pin_outlined
            : Icons.push_pin_rounded,
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        icon: widget.chat.archived
            ? Icons.unarchive_rounded
            : Icons.archive_outlined,
      ),
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onPin();
        } else {
          widget.onArchive();
        }
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onLongPress: () {
          HapticsService.warning();
          widget.onMute();
        },
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: NoctisDurations.tap,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _down
                ? theme.colorScheme.surface
                : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: <Widget>[
              ChatAvatar(chat: widget.chat, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (widget.chat.pinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (widget.chat.isChannel)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.campaign_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (widget.chat.isGroup)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.groups_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            widget.chat.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.chat.muted)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (widget.chat.ttlSeconds != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.timelapse_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          DateFormat.Hm().format(widget.chat.lastMessageAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.chat.lastMessage,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.chat.unread > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.chat.muted
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.chat.unread}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: widget.chat.muted
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({required this.alignment, required this.icon});
  final Alignment alignment;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: theme.colorScheme.onSurface),
    );
  }
}

class _ArchivedTile extends StatelessWidget {
  const _ArchivedTile({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant, width: 1),
                ),
                child: Icon(
                  Icons.archive_outlined,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Архив',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Скрыто чатов: $count',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            searching ? Icons.search_off_rounded : Icons.chat_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            searching ? 'Ничего не найдено' : 'Здесь будут ваши чаты',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Попробуйте изменить запрос'
                : 'Нажмите карандаш, чтобы создать чат, группу или канал',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
