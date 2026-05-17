// Каталог монохромных «иконных» реакций NOCTIS.
// Хранятся как строковые ID, рисуются Material-иконками
// (заполнённой и контурной) в строгой чёрно-белой эстетике.
import 'package:flutter/material.dart';

class NoctisReaction {
  const NoctisReaction({
    required this.id,
    required this.label,
    required this.outlined,
    required this.filled,
  });

  final String id;
  final String label;
  final IconData outlined;
  final IconData filled;
}

class NoctisReactions {
  const NoctisReactions._();

  static const List<NoctisReaction> all = <NoctisReaction>[
    NoctisReaction(
      id: 'thumb',
      label: 'Лайк',
      outlined: Icons.thumb_up_outlined,
      filled: Icons.thumb_up_rounded,
    ),
    NoctisReaction(
      id: 'heart',
      label: 'Сердце',
      outlined: Icons.favorite_outline_rounded,
      filled: Icons.favorite_rounded,
    ),
    NoctisReaction(
      id: 'fire',
      label: 'Огонь',
      outlined: Icons.local_fire_department_outlined,
      filled: Icons.local_fire_department_rounded,
    ),
    NoctisReaction(
      id: 'star',
      label: 'Звезда',
      outlined: Icons.star_outline_rounded,
      filled: Icons.star_rounded,
    ),
    NoctisReaction(
      id: 'bolt',
      label: 'Молния',
      outlined: Icons.bolt_outlined,
      filled: Icons.bolt_rounded,
    ),
    NoctisReaction(
      id: 'check',
      label: 'Согласен',
      outlined: Icons.check_circle_outline_rounded,
      filled: Icons.check_circle_rounded,
    ),
  ];

  static NoctisReaction byId(String id) {
    return all.firstWhere(
      (NoctisReaction r) => r.id == id,
      orElse: () => all.first,
    );
  }
}
