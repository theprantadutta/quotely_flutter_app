import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/components/settings_screen/appearance/appearance_screen.dart';
import 'package:quotely_flutter_app/screens/quote_of_the_day_list_screen.dart';
import 'package:quotely_flutter_app/screens/quote_of_the_day_screen.dart';
import 'package:quotely_flutter_app/screens/settings_notification_screen.dart';
import 'package:quotely_flutter_app/screens/tab_screens/authors_screen.dart';

import '../screen_arguments/author_detail_screen_arguments.dart';
import '../screens/author_detail_screen.dart';
import '../screens/settings_offline_support_screen.dart';
import '../screens/tab_screens/favourites_screen.dart';
import '../screens/tab_screens/home_screen.dart';
import '../screens/tab_screens/settings_screen.dart';
import 'bottom-navigation/bottom_navigation_layout.dart';

class AppNavigation {
  AppNavigation._();

  static String initial = HomeScreen.kRouteName;

  // Private navigators
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorHome =
      GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  static final _shellNavigatorFavourites =
      GlobalKey<NavigatorState>(debugLabel: 'shellFavourites');
  static final _shellNavigatorAuthors =
      GlobalKey<NavigatorState>(debugLabel: 'shellAuthors');
  static final _shellNavigatorSettings =
      GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

  // GoRouter configuration
  static final GoRouter router = GoRouter(
    initialLocation: initial,
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    routes: [
      // /// OnBoardingScreen
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: OnBoardingScreen.route,
      //   name: "OnBoarding",
      //   builder: (context, state) => OnBoardingScreen(
      //     key: state.pageKey,
      //   ),
      // ),

      // /// OnBoardingThemeScreen
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: OnboardingThemeScreen.route,
      //   name: "OnBoardingTheme",
      //   builder: (context, state) => OnboardingThemeScreen(
      //     key: state.pageKey,
      //   ),
      // ),

      /// MainWrapper
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavigationLayout(
            navigationShell: navigationShell,
          );
        },
        branches: <StatefulShellBranch>[
          /// Branch Home
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHome,
            routes: <RouteBase>[
              GoRoute(
                path: HomeScreen.kRouteName,
                name: "Home",
                pageBuilder: (context, state) => reusableTransitionPage(
                  state: state,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _shellNavigatorFavourites,
            routes: <RouteBase>[
              GoRoute(
                path: FavouritesScreen.kRouteName,
                name: "Favourites",
                pageBuilder: (context, state) => reusableTransitionPage(
                  state: state,
                  child: const FavouritesScreen(),
                ),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _shellNavigatorAuthors,
            routes: <RouteBase>[
              GoRoute(
                path: AuthorsScreen.kRouteName,
                name: "Authors",
                pageBuilder: (context, state) => reusableTransitionPage(
                  state: state,
                  child: const AuthorsScreen(),
                ),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettings,
            routes: <RouteBase>[
              GoRoute(
                path: SettingsScreen.kRouteName,
                name: "Settings",
                pageBuilder: (context, state) => reusableTransitionPage(
                  state: state,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      /// View Quote of the Day Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: QuoteOfTheDayScreen.kRouteName,
        name: "Quote of the Day",
        builder: (context, state) => QuoteOfTheDayScreen(
          key: state.pageKey,
        ),
      ),

      /// View all Quote of the Day Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: QuoteOfTheDayListScreen.kRouteName,
        name: "Quote of the Day List",
        builder: (context, state) => QuoteOfTheDayListScreen(
          key: state.pageKey,
        ),
      ),

      /// View Settings Appearance
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppearanceScreen.kRouteName,
        name: "Appearance",
        builder: (context, state) => AppearanceScreen(
          key: state.pageKey,
        ),
      ),

      /// View Settings Appearance
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: SettingsNotificationScreen.kRouteName,
        name: "Settings Notification",
        builder: (context, state) => SettingsNotificationScreen(
          key: state.pageKey,
        ),
      ),

      /// View Settings Offline Support
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: SettingsOfflineSupportScreen.kRouteName,
        name: "Settings Offline Support",
        builder: (context, state) => SettingsOfflineSupportScreen(
          key: state.pageKey,
        ),
      ),

      /// Author Detail
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AuthorDetailScreen.kRouteName,
        name: "Author Detail",
        builder: (context, state) {
          final authorDetailScreenArguments =
              state.extra as AuthorDetailScreenArguments;
          return AuthorDetailScreen(
            key: state.pageKey,
            authorDetailScreenArguments: authorDetailScreenArguments,
          );
        },
      ),
    ],
  );

  static CustomTransitionPage<void> reusableTransitionPage({
    required state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      restorationId: state.pageKey.value,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
