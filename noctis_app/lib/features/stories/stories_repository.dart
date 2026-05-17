// Хранилище сторис (in-memory).
// Поддерживает текстовые истории, истории с картинкой и реакции.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class StoryItem {
  const StoryItem({
    required this.id,
    required this.text,
    required this.publishedAt,
    this.imagePath,
    this.seen = false,
    this.reactions = const <String>[],
  });

  final String id;
  final String text;
  final DateTime publishedAt;
  final String? imagePath;
  final bool seen;
  final List<String> reactions;

  StoryItem copyWith({
    bool? seen,
    List<String>? reactions,
  }) {
    return StoryItem(
      id: id,
      text: text,
      publishedAt: publishedAt,
      imagePath: imagePath,
      seen: seen ?? this.seen,
      reactions: reactions ?? this.reactions,
    );
  }
}

@immutable
class StoryAuthor {
  const StoryAuthor({
    required this.id,
    required this.name,
    required this.stories,
    this.isMine = false,
    this.avatarPath,
  });

  final String id;
  final String name;
  final List<StoryItem> stories;
  final bool isMine;
  final String? avatarPath;

  bool get allSeen => stories.every((StoryItem s) => s.seen);

  String get initials {
    final List<String> parts =
        name.split(' ').where((String s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'N';
    if (parts.length < 2) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  StoryAuthor copyWith({
    String? name,
    List<StoryItem>? stories,
    String? avatarPath,
  }) {
    return StoryAuthor(
      id: id,
      name: name ?? this.name,
      isMine: isMine,
      stories: stories ?? this.stories,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  StoryAuthor markAllSeen() => copyWith(
        stories: <StoryItem>[
          for (final StoryItem s in stories) s.copyWith(seen: true),
        ],
      );
}

class StoriesController extends StateNotifier<List<StoryAuthor>> {
  StoriesController()
      : super(const <StoryAuthor>[
          StoryAuthor(
            id: 'me',
            name: 'Моя история',
            isMine: true,
            stories: <StoryItem>[],
          ),
        ]);

  void markSeen(String authorId) {
    state = <StoryAuthor>[
      for (final StoryAuthor a in state)
        if (a.id == authorId) a.markAllSeen() else a,
    ];
  }

  void addMyStory({required String text, String? imagePath}) {
    final DateTime now = DateTime.now();
    final StoryItem item = StoryItem(
      id: 'my-${now.microsecondsSinceEpoch}',
      text: text,
      publishedAt: now,
      imagePath: imagePath,
    );
    state = <StoryAuthor>[
      for (final StoryAuthor a in state)
        if (a.isMine)
          a.copyWith(stories: <StoryItem>[...a.stories, item])
        else
          a,
    ];
  }

  void toggleReaction(String authorId, String storyId, String reactionId) {
    state = <StoryAuthor>[
      for (final StoryAuthor a in state)
        if (a.id == authorId)
          a.copyWith(
            stories: <StoryItem>[
              for (final StoryItem s in a.stories)
                if (s.id == storyId)
                  s.copyWith(
                    reactions: s.reactions.contains(reactionId)
                        ? (List<String>.from(s.reactions)..remove(reactionId))
                        : <String>[...s.reactions, reactionId],
                  )
                else
                  s,
            ],
          )
        else
          a,
    ];
  }

  void updateMyAvatar(String? path, String? name) {
    state = <StoryAuthor>[
      for (final StoryAuthor a in state)
        if (a.isMine)
          a.copyWith(avatarPath: path, name: name ?? a.name)
        else
          a,
    ];
  }
}

final StateNotifierProvider<StoriesController, List<StoryAuthor>>
    storiesProvider =
    StateNotifierProvider<StoriesController, List<StoryAuthor>>(
  (Ref ref) => StoriesController(),
);
