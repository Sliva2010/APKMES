// Роутер NOCTIS на go_router.
// Все переходы идут через это место для единого UX.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/phone_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/chats/chat_list_screen.dart';
import '../../features/chats/direct_chat_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../animation/durations_curves.dart';

class GoRouterConfig {
  const GoRouterConfig(this.router);
  final GoRouter router;
}

final Provider<GoRouterConfig> routerProvider = Provider<GoRouterConfig>((
  Ref ref,
) {
  // Прокидываем изменения авторизации в Listenable для go_router.
  final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  final ProviderSubscription<AuthState> sub =
      ref.listen<AuthState>(authControllerProvider, (AuthState? _, AuthState __) {
    notifier.value = notifier.value + 1;
  });

  final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthStatus status = ref.read(authControllerProvider).status;
      final bool authed = status == AuthStatus.authenticated;
      final bool atAuthRoute = state.matchedLocation.startsWith('/welcome') ||
          state.matchedLocation.startsWith('/phone') ||
          state.matchedLocation.startsWith('/otp') ||
          state.matchedLocation.startsWith('/profile-setup');

      if (authed && atAuthRoute) {
        return '/chats';
      }
      if (!authed && !atAuthRoute) {
        return '/welcome';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/welcome',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: '/phone',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const PhoneInputScreen()),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String phone =
              (state.extra as Map<String, dynamic>?)?['phone'] as String? ?? '';
          return _buildPage(state, OtpInputScreen(phone: phone));
        },
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const ProfileSetupScreen()),
      ),
      GoRoute(
        path: '/chats',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const ChatListScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: ':chatId',
            pageBuilder: (BuildContext context, GoRouterState state) {
              final String chatId = state.pathParameters['chatId'] ?? '';
              return _buildPage(state, DirectChatScreen(chatId: chatId));
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const SettingsScreen()),
      ),
    ],
  );

  ref.onDispose(() {
    sub.close();
    router.dispose();
    notifier.dispose();
  });
  return GoRouterConfig(router);
});

CustomTransitionPage<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: NoctisDurations.screen,
    reverseTransitionDuration: NoctisDurations.screen,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final CurvedAnimation curve = CurvedAnimation(
        parent: animation,
        curve: NoctisCurves.standard,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.04),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}
