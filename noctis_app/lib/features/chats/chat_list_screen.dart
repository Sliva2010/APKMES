// Главный экран — список чатов с swipe-действиями (архив, mute, pin).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../stories/stories_strip.dart';
import 'chat_repository.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ChatSummary> all = ref.watch(chatListProvider);
    final List<ChatSummary> chats = <ChatSummary>[
      ...all.where((ChatSummary c) => !c.archived && c.pinned),
      ...all.where((ChatSummary c) => !c.archived && !c.pinned),
    ];
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOCTIS'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              HapticsService.tap();
              context.push('/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            onPressed: () {
              HapticsService.tap();
              context.push('/discover');
            },
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            onPressed: () {
              HapticsService.tap();
              context.push('/tools');
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              HapticsService.tap();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(child: StoriesStrip()),
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
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        onPressed: () {
          HapticsService.tap();
          context.push('/chats/new');
        },
        child: const Icon(Icons.edit_rounded),
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
        icon: widget.chat.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        icon: widget.chat.archived ? Icons.unarchive_rounded : Icons.archive_outlined,
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
              _Avatar(initials: widget.chat.initials),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
