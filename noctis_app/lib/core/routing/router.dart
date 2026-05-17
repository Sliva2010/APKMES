// Роутер NOCTIS на go_router.
// Ветвь /onboarding|welcome|phone|otp|profile-setup для авторизации,
// StatefulShellRoute для главного хаба с 4 вкладками.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/phone_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/chats/chat_list_screen.dart';
import '../../features/chats/contact_profile_screen.dart';
import '../../features/chats/direct_chat_screen.dart';
import '../../features/chats/new_chat_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/hub/hub_shell.dart';
import '../../features/mini_tools/calculator_tool.dart';
import '../../features/mini_tools/mini_tools_screen.dart';
import '../../features/mini_tools/timer_tool.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/appearance_screen.dart';
import '../../features/settings/privacy_screen.dart';
import '../../features/settings/security_screen.dart';
import '../../features/settings/sessions_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../animation/durations_curves.dart';

class GoRouterConfig {
  const GoRouterConfig(this.router);
  final GoRouter router;
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

final Provider<GoRouterConfig> routerProvider =
    Provider<GoRouterConfig>((Ref ref) {
  final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  final ProviderSubscription<AuthState> sub = ref.listen<AuthState>(
    authControllerProvider,
    (AuthState? _, AuthState __) {
      notifier.value = notifier.value + 1;
    },
  );

  final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/onboarding',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthStatus status = ref.read(authControllerProvider).status;
      final bool authed = status == AuthStatus.authenticated;
      final String loc = state.matchedLocation;
      final bool atAuthRoute = loc.startsWith('/welcome') ||
          loc.startsWith('/onboarding') ||
          loc.startsWith('/phone') ||
          loc.startsWith('/otp') ||
          loc.startsWith('/profile-setup');

      if (authed && atAuthRoute) {
        return '/chats';
      }
      if (!authed && !atAuthRoute) {
        return '/onboarding';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const OnboardingScreen()),
      ),
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
        path: '/premium',
        parentNavigatorKey: _rootKey,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const PremiumScreen()),
      ),
      // Главный хаб с нижней навигацией.
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell shell,
        ) =>
            HubShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          // Вкладка 1: чаты.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/chats',
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _buildPage(state, const ChatListScreen()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const NewChatScreen()),
                  ),
                  GoRoute(
                    path: ':chatId',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) {
                      final String chatId =
                          state.pathParameters['chatId'] ?? '';
                      return _buildPage(
                          state, DirectChatScreen(chatId: chatId));
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'profile',
                        parentNavigatorKey: _rootKey,
                        pageBuilder:
                            (BuildContext context, GoRouterState state) {
                          final String chatId =
                              state.pathParameters['chatId'] ?? '';
                          return _buildPage(
                              state, ContactProfileScreen(chatId: chatId));
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/search',
                parentNavigatorKey: _rootKey,
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _buildPage(state, const SearchScreen()),
              ),
            ],
          ),
          // Вкладка 2: Discover.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/discover',
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _buildPage(state, const DiscoverScreen()),
              ),
            ],
          ),
          // Вкладка 3: инструменты.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/tools',
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _buildPage(state, const MiniToolsScreen()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'calculator',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const CalculatorTool()),
                  ),
                  GoRoute(
                    path: 'timer',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const TimerTool()),
                  ),
                ],
              ),
            ],
          ),
          // Вкладка 4: настройки.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _buildPage(state, const SettingsScreen()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'appearance',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const AppearanceScreen()),
                  ),
                  GoRoute(
                    path: 'security',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const SecurityScreen()),
                  ),
                  GoRoute(
                    path: 'privacy',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const PrivacyScreen()),
                  ),
                  GoRoute(
                    path: 'sessions',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const SessionsScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
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
