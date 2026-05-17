// Роутер NOCTIS на go_router.
// Auth-ветви: /onboarding -> /welcome -> /register -> /chats.
// Главный хаб с двумя вкладками (Чаты, Настройки).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/archive/archived_chats_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/chats/chat_list_screen.dart';
import '../../features/chats/channel_create_screen.dart';
import '../../features/chats/contact_profile_screen.dart';
import '../../features/chats/direct_chat_screen.dart';
import '../../features/chats/group_create_screen.dart';
import '../../features/chats/new_chat_screen.dart';
import '../../features/hub/hub_shell.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/appearance_screen.dart';
import '../../features/settings/chats_settings_screen.dart';
import '../../features/settings/edit_profile_screen.dart';
import '../../features/settings/language_screen.dart';
import '../../features/settings/notifications_screen.dart';
import '../../features/settings/premium_badge_screen.dart';
import '../../features/settings/privacy_screen.dart';
import '../../features/settings/security_screen.dart';
import '../../features/settings/sessions_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/storage_screen.dart';
import '../../features/stories/story_compose_screen.dart';
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
          loc.startsWith('/register');

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
        path: '/register',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/premium',
        parentNavigatorKey: _rootKey,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const PremiumScreen()),
      ),
      GoRoute(
        path: '/story/compose',
        parentNavigatorKey: _rootKey,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _buildPage(state, const StoryComposeScreen()),
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
                    path: 'group',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const GroupCreateScreen()),
                  ),
                  GoRoute(
                    path: 'channel',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const ChannelCreateScreen()),
                  ),
                  GoRoute(
                    path: 'archived',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const ArchivedChatsScreen()),
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
          // Вкладка 2: настройки.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    _buildPage(state, const SettingsScreen()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'profile',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const EditProfileScreen()),
                  ),
                  GoRoute(
                    path: 'appearance',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const AppearanceScreen()),
                  ),
                  GoRoute(
                    path: 'notifications',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const NotificationsScreen()),
                  ),
                  GoRoute(
                    path: 'chats',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const ChatsSettingsScreen()),
                  ),
                  GoRoute(
                    path: 'language',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const LanguageScreen()),
                  ),
                  GoRoute(
                    path: 'storage',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const StorageScreen()),
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
                  GoRoute(
                    path: 'badge',
                    parentNavigatorKey: _rootKey,
                    pageBuilder:
                        (BuildContext context, GoRouterState state) =>
                            _buildPage(state, const PremiumBadgeScreen()),
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
