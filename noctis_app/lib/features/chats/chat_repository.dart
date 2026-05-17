// Локальный репозиторий чатов.
// На текущем этапе — in-memory демо-данные для UX-демонстрации.
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
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unread;

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
  });

  final String id;
  final bool fromMe;
  final String text;
  final DateTime sentAt;
  final bool read;
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
      ),
      ChatMessage(
        id: 'a3',
        fromMe: false,
        text: 'Да, отлично. Тот же кафе?',
        sentAt: now.subtract(const Duration(minutes: 35)),
        read: true,
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
