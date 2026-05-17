// Просмотрщик сторис: автопереход, тапы, индикатор сегментов.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animation/haptics_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final StoryAuthor a = _author;
    final ThemeData theme = Theme.of(context);
    if (a.stories.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final StoryItem story = a.stories[_index];
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
            child: Container(
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
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(32, 96, 32, 96),
              child: Text(
                story.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NoctisSans',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
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
                                          child: Container(color: Colors.white),
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
                        backgroundColor:
                            Colors.white.withOpacity(0.15),
                        child: Text(
                          a.initials,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
        ],
      ),
    );
  }
}
