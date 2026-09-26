import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';
import '../screens/appearance_screen.dart';
import '../screens/author_detail_screen.dart';
import '../screens/debug_components_screen.dart';
import '../screens/interests_screen.dart';
import '../screens/notifications_onboarding_screen.dart';
import '../screens/offline_library_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/past_messages_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_notification_screen.dart';
import '../screens/support_us_screen.dart';
import '../screens/tab_screens/facts_screen.dart';
import '../screens/tab_screens/home_screen.dart';
import '../screens/tab_screens/people_screen.dart';
import '../screens/tab_screens/saved_screen.dart';
import '../screens/tab_screens/scenes_screen.dart';
import '../screens/title_detail_screen.dart';
import '../screens/you_screen.dart';
import '../service_locator/init_service_locators.dart';
import 'bottom-navigation/bottom_navigation_layout.dart';
import 'routes.dart';

class AppNavigation {
  AppNavigation._();

  static String initial = Routes.today;

  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellToday = GlobalKey<NavigatorState>(debugLabel: 'today');
  static final _shellScenes = GlobalKey<NavigatorState>(debugLabel: 'scenes');
  static final _shellSaved = GlobalKey<NavigatorState>(debugLabel: 'saved');
  static final _shellPeople = GlobalKey<NavigatorState>(debugLabel: 'people');
  static final _shellFacts = GlobalKey<NavigatorState>(debugLabel: 'facts');

  static GoRoute _pushed(String path, Widget Function(GoRouterState) build) =>
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: path,
        builder: (context, state) => build(state),
      );

  static GoRoute _tab(String path, Widget child) => GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        NoTransitionPage(key: state.pageKey, child: child),
  );

  static final GoRouter router = GoRouter(
    initialLocation: initial,
    debugLogDiagnostics: kDebugMode,
    navigatorKey: rootNavigatorKey,
    observers: [
      if (getIt.isRegistered<FirebaseAnalytics>())
        FirebaseAnalyticsObserver(analytics: getIt.get<FirebaseAnalytics>()),
    ],
    // Old paths (still sent by notifications) land on their new homes.
    redirect: (context, state) {
      final target = kLegacyRedirects[state.uri.path];
      if (target == null) return null;
      final extra = state.uri.queryParameters;
      if (extra.isEmpty) return target;
      final uri = Uri.parse(target);
      return uri
          .replace(queryParameters: {...uri.queryParameters, ...extra})
          .toString();
    },
    routes: [
      _pushed(Routes.onboarding, (s) => OnboardingScreen(key: s.pageKey)),
      _pushed(
        Routes.interests,
        (s) => InterestsScreen(key: s.pageKey, isEditing: s.extra == true),
      ),
      _pushed(
        Routes.notificationsOnboarding,
        (s) => NotificationsOnboardingScreen(key: s.pageKey),
      ),

      StatefulShellRoute.indexedStack(
        redirect: (context, state) async {
          final preferences = await SharedPreferences.getInstance();
          if (!(preferences.getBool('onboardingShown') ?? false)) {
            await preferences.setBool('onboardingShown', true);
            return Routes.onboarding;
          }
          if (!(preferences.getBool(kHasSelectedInterestsKey) ?? false)) {
            return Routes.interests;
          }
          if (!(preferences.getBool(kHasSeenNotificationPrompt) ?? false)) {
            return Routes.notificationsOnboarding;
          }
          return null;
        },
        builder: (context, state, navigationShell) =>
            BottomNavigationLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellToday,
            routes: [_tab(Routes.today, const HomeScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellScenes,
            routes: [_tab(Routes.scenes, const ScenesScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellSaved,
            routes: [_tab(Routes.saved, const SavedScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellPeople,
            routes: [_tab(Routes.people, const PeopleScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellFacts,
            routes: [_tab(Routes.facts, const FactsScreen())],
          ),
        ],
      ),

      _pushed(Routes.you, (s) => YouScreen(key: s.pageKey)),
      _pushed(Routes.appearance, (s) => AppearanceScreen(key: s.pageKey)),
      _pushed(
        Routes.notifications,
        (s) => SettingsNotificationScreen(key: s.pageKey),
      ),
      _pushed(
        Routes.offlineLibrary,
        (s) => OfflineLibraryScreen(key: s.pageKey),
      ),
      _pushed(Routes.support, (s) => SupportUsScreen(key: s.pageKey)),
      _pushed(
        Routes.pastMessages,
        (s) => PastMessagesScreen(
          key: s.pageKey,
          initialKind: PastKind.parse(s.uri.queryParameters['type']),
          highlightLatest: s.uri.queryParameters['latest'] == '1',
          highlightId: s.uri.queryParameters['highlight'],
        ),
      ),
      _pushed(
        '${Routes.titleBase}/:id',
        (s) => TitleDetailScreen(
          key: s.pageKey,
          titleId: s.pathParameters['id']!,
          focusQuoteId: s.uri.queryParameters['quote'],
          focusCharacterId: s.uri.queryParameters['character'],
        ),
      ),
      _pushed(
        '${Routes.authorBase}/:authorSlug',
        (s) => AuthorDetailScreen(
          key: s.pageKey,
          authorSlug: s.pathParameters['authorSlug']!,
        ),
      ),
      _pushed(Routes.search, (s) => SearchScreen(key: s.pageKey)),
      // Component gallery: debug builds only, so it can't ship.
      if (kDebugMode)
        _pushed(
          Routes.debugComponents,
          (s) => DebugComponentsScreen(key: s.pageKey),
        ),
    ],
  );
}
