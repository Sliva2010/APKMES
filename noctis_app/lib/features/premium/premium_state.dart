// Состояние подписки NOCTIS Premium (демо).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PremiumPlan { monthly, annual }

@immutable
class PremiumState {
  const PremiumState({required this.active, this.plan, this.until});
  final bool active;
  final PremiumPlan? plan;
  final DateTime? until;
}

class PremiumController extends StateNotifier<PremiumState> {
  PremiumController() : super(const PremiumState(active: false));

  void activate(PremiumPlan plan) {
    final DateTime now = DateTime.now();
    state = PremiumState(
      active: true,
      plan: plan,
      until: plan == PremiumPlan.annual
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30)),
    );
  }

  void cancel() {
    state = const PremiumState(active: false);
  }
}

final StateNotifierProvider<PremiumController, PremiumState> premiumProvider =
    StateNotifierProvider<PremiumController, PremiumState>(
  (Ref ref) => PremiumController(),
);
