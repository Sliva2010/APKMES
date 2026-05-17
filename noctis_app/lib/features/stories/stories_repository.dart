// Хранилище сторис (демо-режим, in-memory).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class StoryItem {
  const StoryItem({
    required this.id,
    required this.text,
    required this.publishedAt,
    this.seen = false,
  });

  final String id;
  final String text;
  final DateTime publishedAt;
  final bool seen;

  StoryItem markSeen() => StoryItem(
        id: id,
        text: text,
        publishedAt: publishedAt,
        seen: true,
      );
}

@immutable
class StoryAuthor {
  const StoryAuthor({
    required this.id,
    required this.name,
    required this.stories,
    this.isMine = false,
  });

  final String id;
  final String name;
  final List<StoryItem> stories;
  final bool isMine;

  bool get allSeen => stories.every((StoryItem s) => s.seen);

  String get initials {
    final List<String> parts = name.split(' ');
    if (parts.length < 2) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  StoryAuthor markAllSeen() => StoryAuthor(
        id: id,
        name: name,
        isMine: isMine,
        stories: <StoryItem>[
          for (final StoryItem s in stories) s.markSeen(),
        ],
      );
}

class StoriesController extends StateNotifier<List<StoryAuthor>> {
  StoriesController()
      : super(<StoryAuthor>[
          const StoryAuthor(
            id: 'me',
            name: 'Моя история',
            isMine: true,
            stories: <StoryItem>[],
          ),
          StoryAuthor(
            id: 'demo-anna',
            name: 'Анна Грей',
            stories: <StoryItem>[
              StoryItem(
                id: 'a1',
                text:
                    'Утренний кофе и чистый поток мыслей.\nДоброе утро, ребята.',
                publishedAt:
                    DateTime.now().subtract(const Duration(hours: 1)),
              ),
              StoryItem(
                id: 'a2',
                text: 'Подготовка к встрече.\nВсё идёт по плану.',
                publishedAt:
                    DateTime.now().subtract(const Duration(minutes: 25)),
              ),
            ],
          ),
          StoryAuthor(
            id: 'demo-team',
            name: 'NOCTIS',
            stories: <StoryItem>[
              StoryItem(
                id: 't1',
                text: 'Релиз 1.0\nЧёрно-белая эстетика во всём.',
                publishedAt:
                    DateTime.now().subtract(const Duration(hours: 4)),
              ),
            ],
          ),
        ]);

  void markSeen(String authorId) {
    state = <StoryAuthor>[
      for (final StoryAuthor a in state)
        if (a.id == authorId) a.markAllSeen() else a,
    ];
  }
}

final StateNotifierProvider<StoriesController, List<StoryAuthor>>
    storiesProvider =
    StateNotifierProvider<StoriesController, List<StoryAuthor>>(
  (Ref ref) => StoriesController(),
);
