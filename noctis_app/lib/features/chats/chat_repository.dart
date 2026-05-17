// Локальный репозиторий чатов и сообщений.
// При первом запуске содержит только «Избранное» (Saved Messages).
// Поддерживает реакции, ответы, исчезающие сообщения, вложения, голосовые,
// видеосообщения, файлы, опросы, группы и каналы.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChatKind { saved, direct, group, channel }

@immutable
class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unread,
    this.archived = false,
    this.pinned = false,
    this.muted = false,
    this.blocked = false,
    this.ttlSeconds,
    this.kind = ChatKind.direct,
    this.username,
    this.bio,
    this.avatarPath,
    this.members = const <String>[],
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unread;
  final bool archived;
  final bool pinned;
  final bool muted;
  final bool blocked;

  /// TTL для исчезающих сообщений (секунды). null — выключено.
  final int? ttlSeconds;

  final ChatKind kind;
  final String? username;
  final String? bio;
  final String? avatarPath;
  final List<String> members;

  bool get isSaved => kind == ChatKind.saved;
  bool get isGroup => kind == ChatKind.group;
  bool get isChannel => kind == ChatKind.channel;

  ChatSummary copyWith({
    String? title,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unread,
    bool? archived,
    bool? pinned,
    bool? muted,
    bool? blocked,
    int? ttlSeconds,
    ChatKind? kind,
    String? username,
    String? bio,
    String? avatarPath,
    List<String>? members,
    bool clearTtl = false,
    bool clearAvatar = false,
  }) {
    return ChatSummary(
      id: id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unread: unread ?? this.unread,
      archived: archived ?? this.archived,
      pinned: pinned ?? this.pinned,
      muted: muted ?? this.muted,
      blocked: blocked ?? this.blocked,
      ttlSeconds: clearTtl ? null : (ttlSeconds ?? this.ttlSeconds),
      kind: kind ?? this.kind,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      members: members ?? this.members,
    );
  }

  String get initials {
    final List<String> parts =
        title.split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '·';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

@immutable
class PollOption {
  const PollOption({
    required this.text,
    required this.votes,
    required this.votedByMe,
  });
  final String text;
  final int votes;
  final bool votedByMe;

  PollOption copyWith({int? votes, bool? votedByMe}) => PollOption(
        text: text,
        votes: votes ?? this.votes,
        votedByMe: votedByMe ?? this.votedByMe,
      );
}

@immutable
class PollData {
  const PollData({
    required this.question,
    required this.options,
    required this.multi,
    required this.anonymous,
  });

  final String question;
  final List<PollOption> options;
  final bool multi;
  final bool anonymous;

  int get totalVotes =>
      options.fold(0, (int sum, PollOption o) => sum + o.votes);
}

enum AttachmentKind { image, video, file, videoNote }

@immutable
class Attachment {
  const Attachment({
    required this.kind,
    required this.path,
    this.fileName,
    this.fileSize,
    this.thumbPath,
    this.durationMs,
  });

  final AttachmentKind kind;
  final String path;
  final String? fileName;
  final int? fileSize;
  final String? thumbPath;
  final int? durationMs;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromMe,
    required this.text,
    required this.sentAt,
    required this.read,
    this.replyToId,
    this.replyToText,
    this.reactions = const <String>[],
    this.expiresAt,
    this.voiceWaveform,
    this.voiceDurationMs,
    this.poll,
    this.attachment,
  });

  final String id;
  final bool fromMe;
  final String text;
  final DateTime sentAt;
  final bool read;
  final String? replyToId;
  final String? replyToText;
  final List<String> reactions;

  /// Точное время удаления; null — без TTL.
  final DateTime? expiresAt;

  /// Если задано — сообщение является голосовым.
  final List<double>? voiceWaveform;
  final int? voiceDurationMs;

  /// Если задано — сообщение является опросом.
  final PollData? poll;

  /// Файл/фото/видео/кружок.
  final Attachment? attachment;

  bool get isVoice => voiceWaveform != null;
  bool get isPoll => poll != null;
  bool get hasAttachment => attachment != null;

  ChatMessage copyWith({
    String? text,
    bool? read,
    List<String>? reactions,
    DateTime? expiresAt,
    PollData? poll,
    Attachment? attachment,
  }) {
    return ChatMessage(
      id: id,
      fromMe: fromMe,
      text: text ?? this.text,
      sentAt: sentAt,
      read: read ?? this.read,
      replyToId: replyToId,
      replyToText: replyToText,
      reactions: reactions ?? this.reactions,
      expiresAt: expiresAt ?? this.expiresAt,
      voiceWaveform: voiceWaveform,
      voiceDurationMs: voiceDurationMs,
      poll: poll ?? this.poll,
      attachment: attachment ?? this.attachment,
    );
  }
}

/// Список чатов. Старт — только «Избранное».
final StateProvider<List<ChatSummary>> chatListProvider =
    StateProvider<List<ChatSummary>>((Ref ref) {
  final DateTime now = DateTime.now();
  return <ChatSummary>[
    ChatSummary(
      id: 'saved',
      title: 'Избранное',
      lastMessage: 'Заметки и важные сообщения',
      lastMessageAt: now,
      unread: 0,
      pinned: true,
      kind: ChatKind.saved,
    ),
  ];
});

/// Сообщения. Стартовое «Избранное» — пустое.
final StateProvider<Map<String, List<ChatMessage>>> chatMessagesProvider =
    StateProvider<Map<String, List<ChatMessage>>>((Ref ref) {
  return <String, List<ChatMessage>>{
    'saved': <ChatMessage>[],
  };
});
