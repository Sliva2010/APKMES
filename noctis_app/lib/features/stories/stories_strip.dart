// Лента сторис в монохромном стиле — ленточка над списком чатов.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';
import '../../core/theme/monochrome_palette.dart';
import 'stories_repository.dart';
import 'story_viewer_screen.dart';

class StoriesStrip extends ConsumerWidget {
  const StoriesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<StoryAuthor> authors = ref.watch(storiesProvider);

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: authors.length,
        separatorBuilder: (BuildContext _, int __) => const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int index) {
          final StoryAuthor a = authors[index];
          return _StoryItem(
            author: a,
            onTap: () {
              HapticsService.tap();
              if (a.isMine && a.stories.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Скоро: добавление своей истории',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                PageRouteBuilder<void>(
                  transitionDuration: NoctisDurations.screen,
                  reverseTransitionDuration: NoctisDurations.screen,
                  pageBuilder: (BuildContext _, Animation<double> __,
                          Animation<double> ___) =>
                      StoryViewerScreen(authorId: a.id),
                  transitionsBuilder: (BuildContext _, Animation<double> anim,
                      Animation<double> __, Widget child) {
                    return FadeTransition(opacity: anim, child: child);
                  },
                ),
              );
              ref.read(storiesProvider.notifier).markSeen(a.id);
            },
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({required this.author, required this.onTap});
  final StoryAuthor author;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool ring = author.stories.isNotEmpty;
    final bool seen = author.allSeen;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: <Widget>[
            CustomPaint(
              painter: _StoryRing(
                color: theme.colorScheme.onSurface,
                show: ring,
                seen: seen,
                count: author.stories.length,
              ),
              child: Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.all(3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MonochromePalette.guard(
                    theme.colorScheme.surfaceContainerHighest,
                  ),
                  shape: BoxShape.circle,
                ),
                child: author.isMine
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Center(
                            child: Text(
                              author.initials,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (author.stories.isEmpty)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 14,
                                  color: theme.colorScheme.surface,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Text(
                        author.initials,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              author.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: seen
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
                fontWeight: seen ? FontWeight.w400 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryRing extends CustomPainter {
  _StoryRing({
    required this.color,
    required this.show,
    required this.seen,
    required this.count,
  });

  final Color color;
  final bool show;
  final bool seen;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    if (!show) return;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2 - 1;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = seen ? color.withOpacity(0.35) : color
      ..strokeWidth = 2;

    if (count <= 1) {
      canvas.drawCircle(center, radius, paint);
      return;
    }
    final double gap = 0.18;
    final double sweep = (3.14159 * 2 - gap * count) / count;
    double start = -1.5708;
    for (int i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _StoryRing old) =>
      old.show != show || old.seen != seen || old.count != count;
}
