// Профиль собеседника / чата.
// Большой аватар, действия (Сообщение / Звонок / Видео / Mute / Search),
// общие медиа, ссылки, файлы.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/haptics_service.dart';
import '../calls/call_screen.dart';
import 'chat_repository.dart';

class ContactProfileScreen extends ConsumerWidget {
  const ContactProfileScreen({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ChatSummary chat = ref.watch(chatListProvider).firstWhere(
          (ChatSummary c) => c.id == chatId,
          orElse: () => ChatSummary(
            id: chatId,
            title: 'Чат',
            lastMessage: '',
            lastMessageAt: DateTime.now(),
            unread: 0,
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 280,
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
                            Container(
                              width: 132,
                              height: 132,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                chat.initials,
                                style: TextStyle(
                                  fontFamily: 'NoctisSans',
                                  fontSize: 56,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.surface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              chat.title,
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'был в сети недавно',
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
                      label: chat.muted ? 'Включить' : 'Mute',
                      onTap: () {
                        HapticsService.tap();
                        ref.read(chatListProvider.notifier).state =
                            <ChatSummary>[
                          for (final ChatSummary x
                              in ref.read(chatListProvider))
                            if (x.id == chatId)
                              x.copyWith(muted: !x.muted)
                            else
                              x,
                        ];
                      },
                    ),
                    _ActionButton(
                      icon: Icons.search_rounded,
                      label: 'Поиск',
                      onTap: () => HapticsService.tap(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _Card(
                  children: <Widget>[
                    _InfoRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Никнейм',
                      value: '@${chat.id.replaceAll('demo-', '')}',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.call_outlined,
                      label: 'Телефон',
                      value: '+7 999 ··· ·· ··',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.info_outline_rounded,
                      label: 'О себе',
                      value: 'Любит чёрно-белое и тишину.',
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
                    _LinkRow(
                      icon: Icons.image_outlined,
                      label: 'Медиа',
                      value: '24',
                    ),
                    const Divider(height: 1),
                    _LinkRow(
                      icon: Icons.link_rounded,
                      label: 'Ссылки',
                      value: '8',
                    ),
                    const Divider(height: 1),
                    _LinkRow(
                      icon: Icons.description_outlined,
                      label: 'Файлы',
                      value: '3',
                    ),
                    const Divider(height: 1),
                    _LinkRow(
                      icon: Icons.mic_none_rounded,
                      label: 'Голосовые',
                      value: '12',
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
      onTap: onTap,
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
            child: Icon(icon,
                color: theme.colorScheme.onSurface, size: 22),
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
        border: Border.all(
            color: theme.colorScheme.outlineVariant, width: 1),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(value, style: theme.textTheme.titleMedium),
      subtitle: Text(label, style: theme.textTheme.bodySmall),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
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
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(label, style: theme.textTheme.titleMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(value, style: theme.textTheme.titleMedium),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
