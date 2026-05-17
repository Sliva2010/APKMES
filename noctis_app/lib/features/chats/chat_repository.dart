// Локальный репозиторий чатов и сообщений (демо-режим).
// Поддерживает реакции, ответы и исчезающие сообщения.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.ttlSeconds,
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unread;
  final bool archived;
  final bool pinned;
  final bool muted;

  /// TTL для исчезающих сообщений (секунды). null — выключено.
  final int? ttlSeconds;

  ChatSummary copyWith({
    String? title,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unread,
    bool? archived,
    bool? pinned,
    bool? muted,
    int? ttlSeconds,
    bool clearTtl = false,
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
      ttlSeconds: clearTtl ? null : (ttlSeconds ?? this.ttlSeconds),
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

  bool get isVoice => voiceWaveform != null;

  ChatMessage copyWith({
    String? text,
    bool? read,
    List<String>? reactions,
    DateTime? expiresAt,
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
    );
  }
}

final StateProvider<List<ChatSummary>> chatListProvider =
    StateProvider<List<ChatSummary>>((Ref ref) {
  final DateTime now = DateTime.now();
  return <ChatSummary>[
    ChatSummary(
      id: 'demo-saved',
      title: 'Сохранённые',
      lastMessage: 'Заметка: купить кофе и проверить почту',
      lastMessageAt: now.subtract(const Duration(minutes: 8)),
      unread: 0,
      pinned: true,
    ),
    ChatSummary(
      id: 'demo-anna',
      title: 'Анна Грей',
      lastMessage: 'Окей, до встречи в семь',
      lastMessageAt: now.subtract(const Duration(minutes: 32)),
      unread: 2,
    ),
    ChatSummary(
      id: 'demo-team',
      title: 'NOCTIS Team',
      lastMessage: 'Илья: задеплоили новую тему «Paper»',
      lastMessageAt: now.subtract(const Duration(hours: 2)),
      unread: 5,
    ),
    ChatSummary(
      id: 'demo-design',
      title: 'Дизайн-комитет',
      lastMessage: 'Подкинул варианты в Figma',
      lastMessageAt: now.subtract(const Duration(hours: 5)),
      unread: 0,
      muted: true,
    ),
  ];
});

final StateProvider<Map<String, List<ChatMessage>>> chatMessagesProvider =
    StateProvider<Map<String, List<ChatMessage>>>((Ref ref) {
  final DateTime now = DateTime.now();
  return <String, List<ChatMessage>>{
    'demo-saved': <ChatMessage>[
      ChatMessage(
        id: 's1',
        fromMe: true,
        text: 'Купить кофе по дороге домой.',
        sentAt: now.subtract(const Duration(minutes: 8)),
        read: true,
      ),
    ],
    'demo-anna': <ChatMessage>[
      ChatMessage(
        id: 'a1',
        fromMe: false,
        text: 'Привет. Поужинаем сегодня?',
        sentAt: now.subtract(const Duration(minutes: 60)),
        read: true,
      ),
      ChatMessage(
        id: 'a2',
        fromMe: true,
        text: 'Конечно. Семь подойдёт?',
        sentAt: now.subtract(const Duration(minutes: 50)),
        read: true,
        replyToId: 'a1',
        replyToText: 'Привет. Поужинаем сегодня?',
      ),
      ChatMessage(
        id: 'a3',
        fromMe: false,
        text: 'Да, отлично. Тот же кафе?',
        sentAt: now.subtract(const Duration(minutes: 35)),
        read: true,
        reactions: <String>['thumb'],
      ),
      ChatMessage(
        id: 'a4',
        fromMe: false,
        text: 'Окей, до встречи в семь',
        sentAt: now.subtract(const Duration(minutes: 32)),
        read: false,
      ),
    ],
    'demo-team': <ChatMessage>[
      ChatMessage(
        id: 't1',
        fromMe: false,
        text: 'Илья: задеплоили новую тему «Paper»',
        sentAt: now.subtract(const Duration(hours: 2)),
        read: false,
      ),
    ],
    'demo-design': <ChatMessage>[
      ChatMessage(
        id: 'd1',
        fromMe: false,
        text: 'Подкинул варианты в Figma',
        sentAt: now.subtract(const Duration(hours: 5)),
        read: true,
      ),
    ],
  };
});
