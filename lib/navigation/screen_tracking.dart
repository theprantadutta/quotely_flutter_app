import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

import '../service_locator/init_service_locators.dart';

/// GA screen names. Pushed screens use them as their GoRoute `name`; the
/// tabs log them from [TabScreenViewTracker].
class ScreenNames {
  ScreenNames._();

  // Onboarding
  static const onboarding = 'onboarding';
  static const interests = 'interests';
  static const notificationsOnboarding = 'notifications_onboarding';

  // Tabs, in branch order (see [tabs]).
  static const today = 'today';
  static const scenes = 'scenes';
  static const saved = 'saved';
  static const people = 'people';
  static const facts = 'facts';
  static const tabs = [today, scenes, saved, people, facts];

  // Pushed
  static const you = 'you';
  static const appearance = 'appearance';
  static const notificationSettings = 'notification_settings';
  static const offlineLibrary = 'offline_library';
  static const support = 'support';
  static const pastMessages = 'past_messages';
  static const titleDetail = 'title_detail';
  static const authorDetail = 'author_detail';
  static const search = 'search';
  static const debugComponents = 'debug_components';

  /// A route's screen name: its GoRoute name, else (a route someone forgot
  /// to name) its path pattern as snake case, so "/download-everything"
  /// still reads as "download_everything".
  static String fromRouteName(String name) {
    if (!name.startsWith('/')) return name;
    final cleaned = name
        .split('/')
        .where((s) => s.isNotEmpty && !s.startsWith(':'))
        .join('_')
        .replaceAll('-', '_');
    return cleaned.isEmpty ? 'root' : cleaned;
  }
}

typedef ScreenViewSink =
    Future<void> Function({
      required String screenName,
      required String screenClass,
    });

/// The single way screen views reach analytics. Fire and forget: never
/// throws, never blocks the caller.
class ScreenAnalytics {
  ScreenAnalytics._();

  /// Replaces Firebase (tests).
  @visibleForTesting
  static ScreenViewSink? sinkOverride;

  static ScreenViewSink? get _sink {
    final override = sinkOverride;
    if (override != null) return override;
    // Not registered in widget tests (and before the locator is ready).
    if (!getIt.isRegistered<FirebaseAnalytics>()) return null;
    final analytics = getIt.get<FirebaseAnalytics>();
    return ({required screenName, required screenClass}) => analytics
        .logScreenView(screenName: screenName, screenClass: screenClass);
  }

  /// Logs a `screen_view`. The class is the screen name too: without one,
  /// Android reports every view as "MainActivity" in GA's default
  /// "Page title and screen class" dimension.
  static void log(String screenName) {
    try {
      final sink = _sink;
      if (sink == null) return;
      unawaited(
        sink(screenName: screenName, screenClass: screenName).catchError((
          Object e,
        ) {
          debugPrint('screen_view $screenName not logged: $e');
        }),
      );
    } catch (e) {
      debugPrint('screen_view $screenName not logged: $e');
    }
  }
}

/// Logs pushed screens on the root navigator by route name. Replaces
/// FirebaseAnalyticsObserver, which sends no screen class.
///
/// The tab shell's page has no name: [TabScreenViewTracker] logs the tabs,
/// so pushing the shell logs nothing here, and popping back to it re-logs
/// the tab underneath (the screen the user is now looking at).
class ScreenViewObserver extends RouteObserver<ModalRoute<dynamic>> {
  /// Dialogs and sheets aren't screens.
  static bool _isScreen(Route<dynamic>? route) => route is PageRoute;

  static void _logNamed(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null) ScreenAnalytics.log(ScreenNames.fromRouteName(name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_isScreen(route)) _logNamed(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null && _isScreen(newRoute)) _logNamed(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute == null || !_isScreen(route)) return;
    if (!_isScreen(previousRoute)) return;
    if (previousRoute.settings.name != null) {
      _logNamed(previousRoute);
    } else {
      final tab = TabScreenViewTracker.currentTab;
      if (tab != null) ScreenAnalytics.log(tab);
    }
  }
}

/// Logs a `screen_view` for the selected tab: once when the tab shell first
/// appears (the launch tab) and again whenever the selection changes,
/// however it changed (tap, back button, deep link). Re-selecting the same
/// tab logs nothing.
class TabScreenViewTracker extends StatefulWidget {
  final int index;
  final Widget child;

  const TabScreenViewTracker({
    super.key,
    required this.index,
    required this.child,
  });

  /// The tab on screen, while the shell exists.
  static String? get currentTab => _active?._tab;
  static _TabScreenViewTrackerState? _active;

  @override
  State<TabScreenViewTracker> createState() => _TabScreenViewTrackerState();
}

class _TabScreenViewTrackerState extends State<TabScreenViewTracker> {
  String? _tab;

  void _log(int index) {
    if (index < 0 || index >= ScreenNames.tabs.length) return;
    TabScreenViewTracker._active = this;
    _tab = ScreenNames.tabs[index];
    ScreenAnalytics.log(_tab!);
  }

  @override
  void initState() {
    super.initState();
    _log(widget.index);
  }

  @override
  void didUpdateWidget(TabScreenViewTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _log(widget.index);
  }

  @override
  void dispose() {
    if (TabScreenViewTracker._active == this) {
      TabScreenViewTracker._active = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
