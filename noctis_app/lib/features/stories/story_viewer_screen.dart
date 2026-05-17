// Просмотрщик сторис: автопереход, тапы, индикатор сегментов, реакции.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animation/haptics_service.dart';
import '../../ui/widgets/noctis_glyph.dart';
import 'stories_repository.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, required this.authorId});

  final String authorId;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _segment = Duration(seconds: 5);

  int _index = 0;
  late AnimationController _progress;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _segment);
    _progress.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _next();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _progress.forward());
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  StoryAuthor get _author {
    final List<StoryAuthor> all = ref.read(storiesProvider);
    return all.firstWhere((StoryAuthor a) => a.id == widget.authorId,
        orElse: () => const StoryAuthor(
              id: '',
              name: '',
              stories: <StoryItem>[],
            ));
  }

  void _next() {
    final StoryAuthor a = _author;
    if (_index + 1 >= a.stories.length) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _index++);
    _progress
      ..reset()
      ..forward();
  }

  void _prev() {
    if (_index == 0) {
      _progress
        ..reset()
        ..forward();
      return;
    }
    setState(() => _index--);
    _progress
      ..reset()
      ..forward();
  }

  void _setPaused(bool v) {
    if (v == _paused) return;
    setState(() => _paused = v);
    if (v) {
      _progress.stop();
    } else {
      _progress.forward();
    }
  }

  void _toggleReaction(String reactionId) {
    HapticsService.selection();
    final StoryAuthor a = _author;
    if (a.stories.isEmpty) return;
    ref
        .read(storiesProvider.notifier)
        .toggleReaction(widget.authorId, a.stories[_index].id, reactionId);
  }

  @override
  Widget build(BuildContext context) {
    final List<StoryAuthor> all = ref.watch(storiesProvider);
    final StoryAuthor a = all.firstWhere(
      (StoryAuthor x) => x.id == widget.authorId,
      orElse: () => const StoryAuthor(id: '', name: '', stories: <StoryItem>[]),
    );
    final ThemeData theme = Theme.of(context);
    if (a.stories.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final StoryItem story = a.stories[_index.clamp(0, a.stories.length - 1)];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onTapDown: (TapDownDetails d) {
              HapticsService.tap();
              final double x = d.globalPosition.dx;
              final double w = MediaQuery.of(context).size.width;
              if (x < w / 3) {
                _prev();
              } else {
                _next();
              }
            },
            onLongPressStart: (_) => _setPaused(true),
            onLongPressEnd: (_) => _setPaused(false),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (story.imagePath != null)
                  Image.file(
                    File(story.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder:
                        (BuildContext _, Object __, StackTrace? ___) =>
                            const _GradientBackground(),
                  )
                else
                  const _GradientBackground(),
                if (story.text.isNotEmpty)
                  Container(
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.fromLTRB(32, 96, 32, 140),
                    decoration: story.imagePath != null
                        ? BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          )
                        : null,
                    child: Text(
                      story.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NoctisSans',
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        shadows: <Shadow>[
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black54,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      for (int i = 0; i < a.stories.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i == a.stories.length - 1 ? 0 : 4,
                            ),
                            child: SizedBox(
                              height: 3,
                              child: Stack(
                                children: <Widget>[
                                  Container(color: Colors.white24),
                                  if (i < _index)
                                    Container(color: Colors.white)
                                  else if (i == _index)
                                    AnimatedBuilder(
                                      animation: _progress,
                                      builder: (BuildContext _, Widget? __) {
                                        return FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _progress.value,
                                          child:
                                              Container(color: Colors.white),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        backgroundImage: a.avatarPath != null
                            ? FileImage(File(a.avatarPath!))
                            : null,
                        child: a.avatarPath == null
                            ? Text(
                                a.initials,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          a.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'NoctisSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Реакции внизу — для чужих историй.
          if (!a.isMine)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (final NoctisReaction r in NoctisReactions.all)
                          IconButton(
                            iconSize: 22,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              story.reactions.contains(r.id)
                                  ? r.filled
                                  : r.outlined,
                              color: Colors.white,
                            ),
                            onPressed: () => _toggleReaction(r.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF1A1A1A),
            Color(0xFF000000),
          ],
        ),
      ),
    );
  }
}
