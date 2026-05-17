// Поиск по чатам, сообщениям, контактам.
// Локальный фильтр поверх ChatRepository — мгновенный отклик.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../chats/chat_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = _query.text.trim().toLowerCase();
    final List<ChatSummary> chats = ref.watch(chatListProvider);
    final Map<String, List<ChatMessage>> messages =
        ref.watch(chatMessagesProvider);

    final List<ChatSummary> chatHits = q.isEmpty
        ? const <ChatSummary>[]
        : chats
            .where((ChatSummary c) => c.title.toLowerCase().contains(q))
            .toList();

    final List<_MessageHit> messageHits = <_MessageHit>[];
    if (q.isNotEmpty) {
      messages.forEach((String chatId, List<ChatMessage> ms) {
        for (final ChatMessage m in ms) {
          if (m.text.toLowerCase().contains(q)) {
            messageHits.add(_MessageHit(chatId: chatId, message: m));
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintText: 'Поиск',
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: <Widget>[
          if (_query.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _query.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: SafeArea(
        child: q.isEmpty
            ? _EmptyHint()
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: <Widget>[
                  if (chatHits.isNotEmpty) ...<Widget>[
                    const _SectionLabel(label: 'ЧАТЫ'),
                    ...chatHits.map(
                      (ChatSummary c) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: Text(
                            c.initials,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(c.title),
                        subtitle: Text(c.lastMessage,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          HapticsService.tap();
                          context.go('/chats/${c.id}');
                        },
                      ),
                    ),
                  ],
                  if (messageHits.isNotEmpty) ...<Widget>[
                    const _SectionLabel(label: 'СООБЩЕНИЯ'),
                    ...messageHits.map(
                      (_MessageHit hit) => _MessageHitTile(
                        hit: hit,
                        query: q,
                        onTap: () {
                          HapticsService.tap();
                          context.go('/chats/${hit.chatId}');
                        },
                      ),
                    ),
                  ],
                  if (chatHits.isEmpty && messageHits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                      child: Center(
                        child: Text(
                          'Ничего не найдено',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _MessageHit {
  const _MessageHit({required this.chatId, required this.message});
  final String chatId;
  final ChatMessage message;
}

class _MessageHitTile extends ConsumerWidget {
  const _MessageHitTile({
    required this.hit,
    required this.query,
    required this.onTap,
  });

  final _MessageHit hit;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ChatSummary chat =
        ref.watch(chatListProvider).firstWhere((ChatSummary c) => c.id == hit.chatId);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          chat.initials,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(chat.title),
      subtitle: _Highlight(text: hit.message.text, needle: query),
      trailing: Text(
        DateFormat.Hm().format(hit.message.sentAt),
        style: theme.textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.text, required this.needle});
  final String text;
  final String needle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (needle.isEmpty) {
      return Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium);
    }
    final String lc = text.toLowerCase();
    final int idx = lc.indexOf(needle);
    if (idx < 0) {
      return Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium);
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: <TextSpan>[
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + needle.length),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          TextSpan(text: text.substring(idx + needle.length)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.search_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Найдите чаты, сообщения и контакты',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
