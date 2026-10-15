import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/premium_background.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/tools/presentation/screens/tools_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/saved/presentation/screens/saved_screen.dart';
import '../../features/voice/presentation/screens/voice_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/knowledge/presentation/screens/knowledge_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // ── Auth & Entry ────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PremiumBackground(child: SplashScreen()),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PremiumBackground(child: OnboardingScreen()),
        ),
      ),
      // ── Main Shell (Bottom Nav) ─────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          // Branch 1: Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                // Keyed by the full URI: ChatScreen reads id/q/draft only in
                // initState, and this branch keeps its State alive, so without
                // a differing key a second /chat?q=... silently drops the
                // param. A plain '/chat' tab tap keeps the same key, and so
                // keeps the open conversation.
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey(state.uri.toString()),
                  child: ChatScreen(
                    conversationId: state.uri.queryParameters['id'],
                    initialPrompt: state.uri.queryParameters['q'],
                    initialDraft: state.uri.queryParameters['draft'],
                  ),
                ),
              ),
            ],
          ),
          // Branch 2: Explore
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ExploreScreen(),
                ),
              ),
            ],
          ),
          // Branch 3: Tools
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tools',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ToolsScreen(),
                ),
              ),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Sub-screens (No Bottom Nav) ─────────────────────────────────────────
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PremiumBackground(child: CalendarScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/knowledge',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PremiumBackground(child: KnowledgeScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PremiumBackground(child: HistoryScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/saved',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PremiumBackground(child: SavedScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PremiumBackground(child: SettingsScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/voice',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PremiumBackground(child: VoiceScreen()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}
