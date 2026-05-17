// Экран Direct_Chat — пузыри, реакции, ответы, исчезающие сообщения, swipe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import 'chat_repository.dart';

class DirectChatScreen extends ConsumerStatefulWidget {
  const DirectChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _ticker;
  ChatMessage? _replyTo;

  @override
  void initState() {
    super.initState();
    // Раз в секунду перерисовываем для отсчёта TTL и удаления просроченных.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _purgeExpired();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _composer.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _purgeExpired() {
    final Map<String, List<ChatMessage>> map = ref.read(chatMessagesProvider);
    final List<ChatMessage>? list = map[widget.chatId];
    if (list == null) return;
    final DateTime now = DateTime.now();
    final List<ChatMessage> alive = list
        .where(
            (ChatMessage m) => m.expiresAt == null || m.expiresAt!.isAfter(now))
        .toList();
    if (alive.length != list.length) {
      ref.read(chatMessagesProvider.notifier).state =
          <String, List<ChatMessage>>{
        ...map,
        widget.chatId: alive,
      };
    }
  }

  void _send() {
    final String text = _composer.text.trim();
    if (text.isEmpty) return;
    HapticsService.tap();

    final ChatSummary chat = ref.read(chatListProvider).firstWhere(
          (ChatSummary c) => c.id == widget.chatId,
          orElse: () => ChatSummary(
            id: widget.chatId,
            title: 'Чат',
            lastMessage: '',
            lastMessageAt: DateTime.now(),
            unread: 0,
          ),
        );

    final Map<String, List<ChatMessage>> map =
        ref.read(chatMessagesProvider.notifier).state;
    final List<ChatMessage> list =
        List<ChatMessage>.from(map[widget.chatId] ?? <ChatMessage>[]);
    final DateTime now = DateTime.now();
    list.add(
      ChatMessage(
        id: 'local-${now.microsecondsSinceEpoch}',
        fromMe: true,
        text: text,
        sentAt: now,
        read: false,
        replyToId: _replyTo?.id,
        replyToText: _replyTo?.text,
        expiresAt: chat.ttlSeconds == null
            ? null
            : now.add(Duration(seconds: chat.ttlSeconds!)),
      ),
    );
    ref.read(chatMessagesProvider.notifier).state = <String, List<ChatMessage>>{
      ...map,
      widget.chatId: list,
    };
    _composer.clear();
    setState(() => _replyTo = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: NoctisDurations.list,
          curve: NoctisCurves.standard,
        );
      }
    });
  }

  void _toggleReaction(ChatMessage m, String emoji) {
    HapticsService.selection();
    final Map<String, List<ChatMessage>> map = ref.read(chatMessagesProvider);
    final List<ChatMessage> list =
        List<ChatMessage>.from(map[widget.chatId] ?? <ChatMessage>[]);
    final int idx = list.indexWhere((ChatMessage x) => x.id == m.id);
    if (idx < 0) return;
    final List<String> reactions = List<String>.from(list[idx].reactions);
    if (reactions.contains(emoji)) {
      reactions.remove(emoji);
    } else {
      reactions.add(emoji);
    }
    list[idx] = list[idx].copyWith(reactions: reactions);
    ref.read(chatMessagesProvider.notifier).state = <String, List<ChatMessage>>{
      ...map,
      widget.chatId: list,
    };
  }

  void _setReply(ChatMessage? m) {
    HapticsService.tap();
    setState(() => _replyTo = m);
    if (m != null) FocusScope.of(context).requestFocus(_focusNode);
  }

  void _deleteMessage(ChatMessage m) {
    HapticsService.warning();
    final Map<String, List<ChatMessage>> map = ref.read(chatMessagesProvider);
    final List<ChatMessage> list =
        List<ChatMessage>.from(map[widget.chatId] ?? <ChatMessage>[])
          ..removeWhere((ChatMessage x) => x.id == m.id);
    ref.read(chatMessagesProvider.notifier).state = <String, List<ChatMessage>>{
      ...map,
      widget.chatId: list,
    };
  }

  void _showMessageMenu(ChatMessage m) async {
    HapticsService.selection();
    final ThemeData theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: <Widget>[
                    for (final String e in <String>['👍', '❤️', '🔥', '😂', '😮', '😢'])
                      InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () {
                          Navigator.pop(context);
                          _toggleReaction(m, e);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Text(e, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Ответить'),
                onTap: () {
                  Navigator.pop(context);
                  _setReply(m);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Скопировать'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Удалить'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(m);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showTtlPicker() {
    HapticsService.tap();
    final ThemeData theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        const List<MapEntry<String, int?>> options =
            <MapEntry<String, int?>>[
          MapEntry<String, int?>('Выключить', null),
          MapEntry<String, int?>('30 секунд', 30),
          MapEntry<String, int?>('1 минута', 60),
          MapEntry<String, int?>('1 час', 3600),
          MapEntry<String, int?>('24 часа', 86400),
          MapEntry<String, int?>('7 дней', 604800),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 12),
              Text(
                'Исчезающие сообщения',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Все новые сообщения исчезнут у обоих участников после прочтения.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              for (final MapEntry<String, int?> opt in options)
                ListTile(
                  leading: const Icon(Icons.timelapse_rounded),
                  title: Text(opt.key),
                  onTap: () {
                    Navigator.pop(context);
                    _setTtl(opt.value);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _setTtl(int? seconds) {
    final List<ChatSummary> chats = ref.read(chatListProvider);
    ref.read(chatListProvider.notifier).state = <ChatSummary>[
      for (final ChatSummary c in chats)
        if (c.id == widget.chatId)
          c.copyWith(ttlSeconds: seconds, clearTtl: seconds == null)
        else
          c,
    ];
    HapticsService.success();
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
    final List<ChatMessage> messages =
        ref.watch(chatMessagesProvider)[widget.chatId] ?? const <ChatMessage>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Text(
                chat.initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          chat.title,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.ttlSeconds != null) ...<Widget>[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.timelapse_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  Text('в сети', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Исчезающие сообщения',
            icon: Icon(
              chat.ttlSeconds == null
                  ? Icons.timelapse_outlined
                  : Icons.timelapse_rounded,
            ),
            onPressed: _showTtlPicker,
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () => HapticsService.tap(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final ChatMessage msg = messages[index];
                  final bool firstOfBlock = index == 0 ||
                      messages[index - 1].fromMe != msg.fromMe;
                  return Padding(
                    padding: EdgeInsets.only(top: firstOfBlock ? 12 : 4),
                    child: _SwipeToReply(
                      onReply: () => _setReply(msg),
                      child: GestureDetector(
                        onLongPress: () => _showMessageMenu(msg),
                        onDoubleTap: () => _toggleReaction(msg, '👍'),
                        child: _MessageBubble(message: msg),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_replyTo != null)
              _ReplyPreview(
                message: _replyTo!,
                onClose: () => setState(() => _replyTo = null),
              ),
            _Composer(
              controller: _composer,
              focusNode: _focusNode,
              onSend: _send,
              ttlSeconds: chat.ttlSeconds,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({required this.child, required this.onReply});
  final Widget child;
  final VoidCallback onReply;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _offset = 0;
  bool _triggered = false;

  static const double _threshold = 56;

  void _update(double dx) {
    setState(() {
      _offset = (_offset + dx).clamp(0.0, 80.0);
      if (!_triggered && _offset > _threshold) {
        _triggered = true;
        HapticsService.success();
      }
    });
  }

  void _end() {
    if (_triggered) {
      widget.onReply();
    }
    setState(() {
      _offset = 0;
      _triggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AnimatedOpacity(
                duration: NoctisDurations.tap,
                opacity: (_offset / _threshold).clamp(0.0, 1.0),
                child: Icon(
                  Icons.reply_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (DragUpdateDetails d) =>
              _update(d.delta.dx),
          onHorizontalDragEnd: (_) => _end(),
          child: AnimatedSlide(
            duration: NoctisDurations.tap,
            offset: Offset(_offset / 250, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool me = message.fromMe;
    final Color bg = me
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final Color fg =
        me ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(me ? 20 : 6),
      bottomRight: Radius.circular(me ? 6 : 20),
    );

    final Duration? remaining = message.expiresAt == null
        ? null
        : message.expiresAt!.difference(DateTime.now());

    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: NoctisDurations.tap,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(color: bg, borderRadius: radius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (message.replyToText != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: fg.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: fg.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        message.replyToText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: fg.withOpacity(0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Text(
                    message.text,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: fg, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (remaining != null) ...<Widget>[
                        Icon(
                          Icons.timelapse_rounded,
                          size: 12,
                          color: fg.withOpacity(0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatRemaining(remaining),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: fg.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        DateFormat.Hm().format(message.sentAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: fg.withOpacity(0.7)),
                      ),
                      if (me) ...<Widget>[
                        const SizedBox(width: 4),
                        Icon(
                          message.read
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: fg.withOpacity(0.85),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message.reactions.join(' '),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inSeconds <= 0) return '0c';
    if (d.inSeconds < 60) return '${d.inSeconds}c';
    if (d.inMinutes < 60) return '${d.inMinutes}м';
    if (d.inHours < 24) return '${d.inHours}ч';
    return '${d.inDays}д';
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.onClose});
  final ChatMessage message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(width: 3, height: 36, color: theme.colorScheme.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Ответ',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                Text(
                  message.text,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.ttlSeconds,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final int? ttlSeconds;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final bool has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => HapticsService.tap(),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              minLines: 1,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.ttlSeconds == null
                    ? 'Сообщение'
                    : 'Исчезающее сообщение',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: NoctisDurations.tap,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _hasText
                ? _SendButton(
                    key: const ValueKey<String>('send'),
                    onTap: widget.onSend,
                  )
                : IconButton(
                    key: const ValueKey<String>('mic'),
                    icon: const Icon(Icons.mic_none_rounded),
                    onPressed: () => HapticsService.tap(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: theme.colorScheme.onPrimary,
          size: 22,
        ),
      ),
    );
  }
}
