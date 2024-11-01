import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/tab_screens/favourites_screen.dart';
import '../screens/tab_screens/home_screen.dart';
import '../screens/tab_screens/quote_of_the_day_screen.dart';
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
  static final _shellNavigatorQuoteOfTheDay =
      GlobalKey<NavigatorState>(debugLabel: 'shellQuoteOfTheDay');
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
            navigatorKey: _shellNavigatorQuoteOfTheDay,
            routes: <RouteBase>[
              GoRoute(
                path: QuoteOfTheDayScreen.kRouteName,
                name: "Wishlist",
                pageBuilder: (context, state) => reusableTransitionPage(
                  state: state,
                  child: const QuoteOfTheDayScreen(),
                ),
              ),
            ],
          ),

          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettings,
            routes: <RouteBase>[
              GoRoute(
                path: SettingsScreen.kRouteName,
                name: "Cart",
                pageBuilder: (context, state) => reusableTransitionPage(
                  state: state,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      /// View all Screen
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: ViewAllScreen.kRouteName,
      //   name: "View All",
      //   builder: (context, state) => ViewAllScreen(
      //     key: state.pageKey,
      //   ),
      // ),
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
