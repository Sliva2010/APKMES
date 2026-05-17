// Экран Direct_Chat — пузыри, реакции, ответы, исчезающие сообщения, swipe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/noctis_glyph.dart';
import '../calls/call_screen.dart';
import '../media/voice_recorder.dart';
import '../stickers/sticker_picker.dart';
import 'chat_repository.dart';
import 'poll_creator_sheet.dart';

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

  void _sendVoice(VoiceRecorderResult voice) {
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
        id: 'voice-${now.microsecondsSinceEpoch}',
        fromMe: true,
        text: 'Голосовое сообщение',
        sentAt: now,
        read: false,
        voiceWaveform: voice.waveform,
        voiceDurationMs: voice.duration.inMilliseconds,
        expiresAt: chat.ttlSeconds == null
            ? null
            : now.add(Duration(seconds: chat.ttlSeconds!)),
      ),
    );
    ref.read(chatMessagesProvider.notifier).state = <String, List<ChatMessage>>{
      ...map,
      widget.chatId: list,
    };
    setState(() {});
  }

  void _openVoiceRecorder() {
    final ThemeData theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetCtx) => VoiceRecorderSheet(
        onComplete: _sendVoice,
      ),
    );
  }

  void _openAttachments() {
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Вложение', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    _AttachmentChip(
                      icon: Icons.image_outlined,
                      label: 'Фото',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Скоро: галерея',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        );
                      },
                    ),
                    _AttachmentChip(
                      icon: Icons.poll_outlined,
                      label: 'Опрос',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _openPollCreator();
                      },
                    ),
                    _AttachmentChip(
                      icon: Icons.location_on_outlined,
                      label: 'Локация',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _sendSystem('Поделился(ась) геопозицией');
                      },
                    ),
                    _AttachmentChip(
                      icon: Icons.contact_page_outlined,
                      label: 'Контакт',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _sendSystem('Поделился(ась) контактом');
                      },
                    ),
                    _AttachmentChip(
                      icon: Icons.description_outlined,
                      label: 'Файл',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _sendSystem('Файл отправлен');
                      },
                    ),
                    _AttachmentChip(
                      icon: Icons.schedule_rounded,
                      label: 'Запланировать',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _sendSystem(
                            'Сообщение будет отправлено по расписанию');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPollCreator() {
    final ThemeData theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetCtx) => PollCreatorSheet(
        onCreate: _sendPoll,
      ),
    );
  }

  void _sendSystem(String text) {
    final Map<String, List<ChatMessage>> map =
        ref.read(chatMessagesProvider.notifier).state;
    final List<ChatMessage> list =
        List<ChatMessage>.from(map[widget.chatId] ?? <ChatMessage>[]);
    list.add(
      ChatMessage(
        id: 'sys-${DateTime.now().microsecondsSinceEpoch}',
        fromMe: true,
        text: text,
        sentAt: DateTime.now(),
        read: false,
      ),
    );
    ref.read(chatMessagesProvider.notifier).state = <String, List<ChatMessage>>{
      ...map,
      widget.chatId: list,
    };
    setState(() {});
  }

  void _sendPoll(PollDraft draft) {
    final Map<String, List<ChatMessage>> map =
        ref.read(chatMessagesProvider.notifier).state;
    final List<ChatMessage> list =
        List<ChatMessage>.from(map[widget.chatId] ?? <ChatMessage>[]);
    final DateTime now = DateTime.now();
    list.add(
      ChatMessage(
        id: 'poll-${now.microsecondsSinceEpoch}',
        fromMe: true,
        text: draft.question,
        sentAt: now,
        read: false,
        poll: PollData(
          question: draft.question,
          options: <PollOption>[
            for (final String s in draft.options)
              PollOption(text: s, votes: 0, votedByMe: false),
          ],
          multi: draft.multi,
          anonymous: draft.anonymous,
        ),
      ),
    );
    ref.read(chatMessagesProvider.notifier).state = <String, List<ChatMessage>>{
      ...map,
      widget.chatId: list,
    };
    setState(() {});
  }

  void _toggleReaction(ChatMessage m, String reactionId) {
    HapticsService.selection();
    final Map<String, List<ChatMessage>> map = ref.read(chatMessagesProvider);
    final List<ChatMessage> list =
        List<ChatMessage>.from(map[widget.chatId] ?? <ChatMessage>[]);
    final int idx = list.indexWhere((ChatMessage x) => x.id == m.id);
    if (idx < 0) return;
    final List<String> reactions = List<String>.from(list[idx].reactions);
    if (reactions.contains(reactionId)) {
      reactions.remove(reactionId);
    } else {
      reactions.add(reactionId);
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    for (final NoctisReaction r in NoctisReactions.all)
                      _ReactionPickerButton(
                        reaction: r,
                        active: m.reactions.contains(r.id),
                        onTap: () {
                          Navigator.pop(context);
                          _toggleReaction(m, r.id);
                        },
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
        title: GestureDetector(
          onTap: () {
            HapticsService.tap();
            context.push('/chats/${widget.chatId}/profile');
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
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
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              HapticsService.tap();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => CallScreen(
                    contactName: chat.title,
                    contactInitials: chat.initials,
                    video: true,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              HapticsService.tap();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => CallScreen(
                    contactName: chat.title,
                    contactInitials: chat.initials,
                  ),
                ),
              );
            },
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
                        onDoubleTap: () => _toggleReaction(msg, 'thumb'),
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
              onMicTap: _openVoiceRecorder,
              onAttach: _openAttachments,
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
                  if (message.isVoice)
                    _VoicePlayer(message: message, fg: fg)
                  else if (message.isPoll)
                    _PollBubbleContent(message: message, fg: fg, bg: bg)
                  else
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
                child: Wrap(
                  spacing: 4,
                  children: <Widget>[
                    for (final String id in message.reactions)
                      _ReactionChip(reaction: NoctisReactions.byId(id)),
                  ],
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

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
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
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Icon(icon,
                  color: theme.colorScheme.onSurface, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PollBubbleContent extends ConsumerWidget {
  const _PollBubbleContent({
    required this.message,
    required this.fg,
    required this.bg,
  });

  final ChatMessage message;
  final Color fg;
  final Color bg;

  void _onVote(BuildContext context, WidgetRef ref, int idx) {
    HapticsService.selection();
    final List<ChatMessage>? current = _findChat(ref);
    if (current == null) return;
    final ChatMessage m = current.firstWhere(
      (ChatMessage x) => x.id == message.id,
      orElse: () => message,
    );
    final PollData? old = m.poll;
    if (old == null) return;
    final List<PollOption> next = <PollOption>[];
    for (int i = 0; i < old.options.length; i++) {
      final PollOption o = old.options[i];
      if (i == idx) {
        if (o.votedByMe) {
          next.add(o.copyWith(votes: o.votes - 1, votedByMe: false));
        } else {
          next.add(o.copyWith(votes: o.votes + 1, votedByMe: true));
        }
      } else {
        if (!old.multi && o.votedByMe) {
          next.add(o.copyWith(votes: o.votes - 1, votedByMe: false));
        } else {
          next.add(o);
        }
      }
    }
    final ChatMessage updated = m.copyWith(
      poll: PollData(
        question: old.question,
        options: next,
        multi: old.multi,
        anonymous: old.anonymous,
      ),
    );
    final Map<String, List<ChatMessage>> map = ref.read(chatMessagesProvider);
    final String chatId = _chatIdFor(ref, m.id) ?? '';
    if (chatId.isEmpty) return;
    final List<ChatMessage> updatedList = <ChatMessage>[
      for (final ChatMessage x in map[chatId] ?? <ChatMessage>[])
        if (x.id == m.id) updated else x,
    ];
    ref.read(chatMessagesProvider.notifier).state = <String, List<ChatMessage>>{
      ...map,
      chatId: updatedList,
    };
  }

  List<ChatMessage>? _findChat(WidgetRef ref) {
    final Map<String, List<ChatMessage>> map = ref.read(chatMessagesProvider);
    for (final List<ChatMessage> list in map.values) {
      if (list.any((ChatMessage x) => x.id == message.id)) return list;
    }
    return null;
  }

  String? _chatIdFor(WidgetRef ref, String messageId) {
    final Map<String, List<ChatMessage>> map = ref.read(chatMessagesProvider);
    for (final MapEntry<String, List<ChatMessage>> e in map.entries) {
      if (e.value.any((ChatMessage x) => x.id == messageId)) return e.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final PollData poll = message.poll!;
    final int total = poll.totalVotes;
    final bool voted =
        poll.options.any((PollOption o) => o.votedByMe);

    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.poll_outlined, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                poll.anonymous ? 'Анонимный опрос' : 'Опрос',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fg.withOpacity(0.85),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            poll.question,
            style: theme.textTheme.titleMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < poll.options.length; i++) ...<Widget>[
            _PollOptionRow(
              option: poll.options[i],
              total: total,
              fg: fg,
              bg: bg,
              voted: voted,
              onTap: () => _onVote(context, ref, i),
            ),
            if (i != poll.options.length - 1) const SizedBox(height: 6),
          ],
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'Никто не проголосовал'
                : 'Голосов: $total${poll.multi ? " · можно несколько" : ""}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollOptionRow extends StatelessWidget {
  const _PollOptionRow({
    required this.option,
    required this.total,
    required this.fg,
    required this.bg,
    required this.voted,
    required this.onTap,
  });

  final PollOption option;
  final int total;
  final Color fg;
  final Color bg;
  final bool voted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double pct = total == 0 ? 0 : option.votes / total;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: <Widget>[
          // Заливка прогресса.
          Positioned.fill(
            child: AnimatedContainer(
              duration: NoctisDurations.list,
              curve: NoctisCurves.standard,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: fg.withOpacity(0.08),
              ),
            ),
          ),
          AnimatedFractionallySizedBox(
            duration: NoctisDurations.list,
            curve: NoctisCurves.standard,
            widthFactor: pct,
            heightFactor: 1,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: option.votedByMe
                    ? fg.withOpacity(0.30)
                    : fg.withOpacity(0.16),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: NoctisDurations.tap,
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option.votedByMe ? fg : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: fg,
                      width: 1.5,
                    ),
                  ),
                  child: option.votedByMe
                      ? Icon(Icons.check_rounded, size: 12, color: bg)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: fg,
                      fontWeight:
                          option.votedByMe ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (voted || option.votes > 0)
                  Text(
                    '${(pct * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.reaction});
  final NoctisReaction reaction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Icon(
        reaction.filled,
        size: 14,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _ReactionPickerButton extends StatelessWidget {
  const _ReactionPickerButton({
    required this.reaction,
    required this.active,
    required this.onTap,
  });

  final NoctisReaction reaction;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.onSurface
              : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          active ? reaction.filled : reaction.outlined,
          size: 22,
          color:
              active ? theme.colorScheme.surface : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({required this.message, required this.fg});
  final ChatMessage message;
  final Color fg;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.message.voiceDurationMs ?? 1000),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticsService.tap();
    if (_c.isAnimating) {
      _c.stop();
      setState(() {});
    } else {
      if (_c.value >= 1) _c.value = 0;
      _c.forward();
      setState(() {});
    }
  }

  String _format(int ms) {
    final int s = ms ~/ 1000;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.fg.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: AnimatedBuilder(
                animation: _c,
                builder: (BuildContext _, Widget? __) => Icon(
                  _c.isAnimating
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: widget.fg,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: _c,
              builder: (BuildContext _, Widget? __) {
                return SizedBox(
                  height: 36,
                  child: CustomPaint(
                    painter: WaveformPainter(
                      samples: widget.message.voiceWaveform!,
                      color: widget.fg,
                      played: _c.value,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _format(widget.message.voiceDurationMs ?? 0),
            style: TextStyle(
              fontFamily: 'NoctisSans',
              fontSize: 11,
              color: widget.fg.withOpacity(0.85),
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
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
    required this.onMicTap,
    required this.onAttach,
    required this.ttlSeconds,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onMicTap;
  final VoidCallback onAttach;
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
            onPressed: () {
              HapticsService.tap();
              widget.onAttach();
            },
          ),
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_rounded),
            onPressed: () {
              HapticsService.tap();
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: theme.colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (BuildContext sheetCtx) => StickerPicker(
                  onPick: (String s) {
                    Navigator.pop(sheetCtx);
                    final TextEditingController c = widget.controller;
                    c.text = c.text + (c.text.isEmpty ? '' : ' ') + s;
                    c.selection = TextSelection.fromPosition(
                      TextPosition(offset: c.text.length),
                    );
                  },
                ),
              );
            },
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
                    onPressed: () {
                      HapticsService.selection();
                      widget.onMicTap();
                    },
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
