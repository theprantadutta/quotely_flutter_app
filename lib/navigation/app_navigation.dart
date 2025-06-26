import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/components/settings_screen/appearance/appearance_screen.dart';
import 'package:quotely_flutter_app/screens/daily_brain_food_screen.dart';
import 'package:quotely_flutter_app/screens/daily_inspiration_screen.dart';
import 'package:quotely_flutter_app/screens/fact_of_the_day_screen.dart';
import 'package:quotely_flutter_app/screens/quote_of_the_day_list_screen.dart';
import 'package:quotely_flutter_app/screens/quote_of_the_day_screen.dart';
import 'package:quotely_flutter_app/screens/settings_notification_screen.dart';
import 'package:quotely_flutter_app/screens/tab_screens/authors_screen.dart';
import 'package:quotely_flutter_app/screens/tab_screens/facts_screen.dart';
import 'package:quotely_flutter_app/screens/weird_fact_wednesday_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/author_detail_screen.dart';
import '../screens/daily_brain_food_list_screen.dart';
import '../screens/daily_inspiration_list_screen.dart';
import '../screens/fact_of_the_day_list_screen.dart';
import '../screens/motivation_monday_list_screen.dart';
import '../screens/motivation_monday_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/settings_download_everything_screen.dart';
import '../screens/support_us_screen.dart';
import '../screens/tab_screens/favorites_screen.dart';
import '../screens/tab_screens/home_screen.dart';
import '../screens/tab_screens/settings_screen.dart';
import '../screens/weird_fact_wednesday_list_screen.dart';
import '../service_locator/init_service_locators.dart';
import 'bottom-navigation/bottom_navigation_layout.dart';

class AppNavigation {
  AppNavigation._();

  static String initial = HomeScreen.kRouteName;

  // Private navigators
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorHome =
      GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  static final _shellNavigatorFavorites =
      GlobalKey<NavigatorState>(debugLabel: 'shellFavorites');
  static final _shellNavigatorAuthors =
      GlobalKey<NavigatorState>(debugLabel: 'shellAuthors');
  static final _shellNavigatorFacts =
      GlobalKey<NavigatorState>(debugLabel: 'shellFacts');
  static final _shellNavigatorSettings =
      GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

  // GoRouter configuration
  static final GoRouter router = GoRouter(
    initialLocation: initial,
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    observers: [
      FirebaseAnalyticsObserver(analytics: getIt.get<FirebaseAnalytics>()),
    ],
    routes: [
      /// OnBoardingScreen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: OnboardingScreen.kRouteName,
        name: "OnBoarding",
        builder: (context, state) => OnboardingScreen(
          key: state.pageKey,
        ),
      ),

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
        redirect: (context, state) async {
          // Check if the onboarding screen has been shown before
          final preferences = await SharedPreferences.getInstance();
          final onboardingShown =
              preferences.getBool('onboardingShown') ?? false;

          // If onboarding wasn't shown, show it and set the flag to true
          if (!onboardingShown) {
            await preferences.setBool('onboardingShown', true);
            return OnboardingScreen.kRouteName; // Redirect to Onboarding screen
          }

          // No redirection needed if none of the conditions apply
          return null;
        },
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
            navigatorKey: _shellNavigatorFavorites,
            routes: <RouteBase>[
              GoRoute(
                path: FavoritesScreen.kRouteName,
                name: "Favorites",
                pageBuilder: (context, state) => reusableTransitionPage(
                  state: state,
                  child: const FavoritesScreen(),
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
            navigatorKey: _shellNavigatorFacts,
            routes: <RouteBase>[
              GoRoute(
                path: FactsScreen.kRouteName,
                name: "Facts",
                pageBuilder: (context, state) => reusableTransitionPage(
                  state: state,
                  child: const FactsScreen(),
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

      /// View Fact of the Day Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: FactOfTheDayScreen.kRouteName,
        name: "Fact of the Day",
        builder: (context, state) => FactOfTheDayScreen(
          key: state.pageKey,
        ),
      ),

      /// View all Fact of the Day Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: FactOfTheDayListScreen.kRouteName,
        name: "Fact of the Day List",
        builder: (context, state) => FactOfTheDayListScreen(
          key: state.pageKey,
        ),
      ),

      /// View Daily Inspiration Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: DailyInspirationScreen.kRouteName,
        name: "Daily Inspiration",
        builder: (context, state) => DailyInspirationScreen(
          key: state.pageKey,
        ),
      ),

      /// View all Daily Inspiration Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: DailyInspirationListScreen.kRouteName,
        name: "Daily Inspiration List",
        builder: (context, state) => DailyInspirationListScreen(
          key: state.pageKey,
        ),
      ),

      /// View Daily Brain Food Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: DailyBrainFoodScreen.kRouteName,
        name: "Daily Brain Food",
        builder: (context, state) => DailyBrainFoodScreen(
          key: state.pageKey,
        ),
      ),

      /// View all Daily Brain Food Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: DailyBrainFoodListScreen.kRouteName,
        name: "Daily Brain Food List",
        builder: (context, state) => DailyBrainFoodListScreen(
          key: state.pageKey,
        ),
      ),

      /// View Motivation Monday Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: MotivationMondayScreen.kRouteName,
        name: "Motivation Monday",
        builder: (context, state) => MotivationMondayScreen(
          key: state.pageKey,
        ),
      ),

      /// View all Monday Motivation Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: MotivationMondayListScreen.kRouteName,
        name: "Monday Motivation List",
        builder: (context, state) => MotivationMondayListScreen(
          key: state.pageKey,
        ),
      ),

      /// View Weird Fact Wednesday Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: WeirdFactWednesdayScreen.kRouteName,
        name: "Weird Fact Wednesday",
        builder: (context, state) => WeirdFactWednesdayScreen(
          key: state.pageKey,
        ),
      ),

      /// View all Weird Fact Wednesday Screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: WeirdFactWednesdayListScreen.kRouteName,
        name: "Weird Fact Wednesday List",
        builder: (context, state) => WeirdFactWednesdayListScreen(
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
        path: SettingsDownloadEverythingScreen.kRouteName,
        name: "Settings Download Everything",
        builder: (context, state) => SettingsDownloadEverythingScreen(
          key: state.pageKey,
        ),
      ),

      /// Author Detail
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${AuthorDetailScreen.kRouteName}/:authorSlug',
        name: "Author Detail",
        builder: (context, state) {
          // final authorDetailScreenArguments =
          //     state.extra as AuthorDetailScreenArguments;
          final authorSlug = state.pathParameters["authorSlug"]!;
          return AuthorDetailScreen(
            key: state.pageKey,
            authorSlug: authorSlug,
          );
        },
      ),

      /// Donation screen
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: SupportUsScreen.kRouteName,
        name: "Donation",
        builder: (context, state) => SupportUsScreen(
          key: state.pageKey,
        ),
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
