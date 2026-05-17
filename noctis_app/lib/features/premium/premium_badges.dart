// Каталог премиум-бейджей NOCTIS.
// 16 значков на выбор; премиум-пользователи могут включать
// до 10 одновременно и они показываются рядом с именем.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumBadge {
  const PremiumBadge({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id;
  final String label;
  final IconData icon;
}

class PremiumBadges {
  const PremiumBadges._();

  static const int maxActive = 10;

  static const List<PremiumBadge> all = <PremiumBadge>[
    PremiumBadge(
      id: 'crown',
      label: 'Корона',
      icon: Icons.workspace_premium_rounded,
    ),
    PremiumBadge(
      id: 'star',
      label: 'Звезда',
      icon: Icons.star_rounded,
    ),
    PremiumBadge(
      id: 'verified',
      label: 'Подтверждён',
      icon: Icons.verified_rounded,
    ),
    PremiumBadge(
      id: 'bolt',
      label: 'Молния',
      icon: Icons.bolt_rounded,
    ),
    PremiumBadge(
      id: 'fire',
      label: 'Огонь',
      icon: Icons.local_fire_department_rounded,
    ),
    PremiumBadge(
      id: 'heart',
      label: 'Сердце',
      icon: Icons.favorite_rounded,
    ),
    PremiumBadge(
      id: 'rocket',
      label: 'Ракета',
      icon: Icons.rocket_launch_rounded,
    ),
    PremiumBadge(
      id: 'trophy',
      label: 'Трофей',
      icon: Icons.emoji_events_rounded,
    ),
    PremiumBadge(
      id: 'gem',
      label: 'Алмаз',
      icon: Icons.diamond_outlined,
    ),
    PremiumBadge(
      id: 'shield',
      label: 'Щит',
      icon: Icons.shield_moon_outlined,
    ),
    PremiumBadge(
      id: 'moon',
      label: 'Луна',
      icon: Icons.nightlight_round,
    ),
    PremiumBadge(
      id: 'auto',
      label: 'Автограф',
      icon: Icons.auto_awesome_rounded,
    ),
    PremiumBadge(
      id: 'leaf',
      label: 'Лист',
      icon: Icons.eco_rounded,
    ),
    PremiumBadge(
      id: 'palette',
      label: 'Палитра',
      icon: Icons.palette_outlined,
    ),
    PremiumBadge(
      id: 'crown2',
      label: 'Лавр',
      icon: Icons.military_tech_rounded,
    ),
    PremiumBadge(
      id: 'check',
      label: 'Чек',
      icon: Icons.check_circle_rounded,
    ),
  ];

  static PremiumBadge byId(String id) {
    return all.firstWhere(
      (PremiumBadge b) => b.id == id,
      orElse: () => all.first,
    );
  }
}

class PremiumBadgesController extends StateNotifier<List<String>> {
  PremiumBadgesController() : super(const <String>['crown']) {
    _restore();
  }

  static const String _key = 'noctis.premium.badges';

  Future<void> _restore() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final List<String>? saved = p.getStringList(_key);
      if (saved != null && saved.isNotEmpty) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setStringList(_key, state);
    } catch (_) {}
  }

  void toggle(String id) {
    if (state.contains(id)) {
      state = List<String>.from(state)..remove(id);
    } else {
      if (state.length >= PremiumBadges.maxActive) return;
      state = <String>[...state, id];
    }
    _persist();
  }

  void clear() {
    state = const <String>[];
    _persist();
  }
}

final StateNotifierProvider<PremiumBadgesController, List<String>>
    premiumBadgesProvider =
    StateNotifierProvider<PremiumBadgesController, List<String>>(
  (Ref ref) => PremiumBadgesController(),
);
