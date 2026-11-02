import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/navigation/screen_tracking.dart';

/// Every screen_view, as (name, class).
final _logged = <(String, String)>[];
List<String> get _names => [for (final (n, _) in _logged) n];

/// The app's shape in miniature: a two-tab indexed-stack shell plus routes
/// pushed on the root navigator, tracked the way AppNavigation tracks them.
GoRouter _router() {
  final root = GlobalKey<NavigatorState>();
  Widget tab(String label) => Scaffold(body: Text(label));
  return GoRouter(
    navigatorKey: root,
    initialLocation: '/home',
    observers: [ScreenViewObserver()],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            TabScreenViewTracker(index: shell.currentIndex, child: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: ScreenNames.today,
                path: '/home',
                pageBuilder: (c, s) =>
                    NoTransitionPage(key: s.pageKey, child: tab('home')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: ScreenNames.scenes,
                path: '/scenes',
                pageBuilder: (c, s) =>
                    NoTransitionPage(key: s.pageKey, child: tab('scenes')),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: root,
        name: ScreenNames.you,
        path: '/you',
        builder: (c, s) => const Scaffold(body: Text('you')),
      ),
      GoRoute(
        parentNavigatorKey: root,
        name: ScreenNames.titleDetail,
        path: '/title/:id',
        builder: (c, s) => Scaffold(body: Text(s.pathParameters['id']!)),
      ),
      // Unnamed on purpose: falls back to its path.
      GoRoute(
        parentNavigatorKey: root,
        path: '/download-everything',
        builder: (c, s) => const Scaffold(body: Text('offline')),
      ),
    ],
  );
}

void main() {
  setUp(() {
    _logged.clear();
    ScreenAnalytics.sinkOverride =
        ({required screenName, required screenClass}) async =>
            _logged.add((screenName, screenClass));
  });
  tearDown(() => ScreenAnalytics.sinkOverride = null);

  testWidgets('tabs and pushed screens each log once, by name', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    // The launch tab, once (the shell page itself logs nothing).
    expect(_names, ['today']);

    router.go('/scenes');
    await tester.pumpAndSettle();
    expect(_names, ['today', 'scenes']);

    // Re-selecting the current tab is not a new screen.
    router.go('/scenes');
    await tester.pumpAndSettle();
    expect(_names, ['today', 'scenes']);

    router.push('/you');
    await tester.pumpAndSettle();
    expect(_names.last, 'you');

    // Back on the tabs: the tab underneath is on screen again.
    router.pop();
    await tester.pumpAndSettle();
    expect(_names, ['today', 'scenes', 'you', 'scenes']);

    router.push('/title/42');
    await tester.pumpAndSettle();
    router.push('/download-everything');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(_names.sublist(4), [
      'title_detail',
      'download_everything',
      'title_detail',
    ]);

    router.go('/home');
    await tester.pumpAndSettle();
    expect(_names.last, 'today');

    // GA's default report groups by screen class: it must be meaningful.
    for (final (name, screenClass) in _logged) {
      expect(screenClass, name);
    }
  });

  testWidgets('dialogs are not screens', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('home'));
    showDialog<void>(context: context, builder: (_) => const Text('dialog'));
    await tester.pumpAndSettle();
    Navigator.of(context, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    expect(_names, ['today']);
  });

  test('a failing analytics backend never reaches the caller', () async {
    ScreenAnalytics.sinkOverride =
        ({required screenName, required screenClass}) =>
            Future<void>.error(Exception('offline'));
    expect(() => ScreenAnalytics.log('today'), returnsNormally);
    ScreenAnalytics.sinkOverride =
        ({required screenName, required screenClass}) =>
            throw StateError('not initialised');
    expect(() => ScreenAnalytics.log('today'), returnsNormally);
    await Future<void>.delayed(Duration.zero);
  });

  test('unnamed routes fall back to a snake-case path', () {
    expect(ScreenNames.fromRouteName('you'), 'you');
    expect(
      ScreenNames.fromRouteName('/settings-notification'),
      'settings_notification',
    );
    expect(ScreenNames.fromRouteName('/title/:id'), 'title');
    expect(ScreenNames.fromRouteName('/'), 'root');
  });

  testWidgets('without Firebase registered, logging is a no-op', (
    tester,
  ) async {
    ScreenAnalytics.sinkOverride = null;
    await tester.pumpWidget(
      const TabScreenViewTracker(index: 0, child: SizedBox()),
    );
    expect(TabScreenViewTracker.currentTab, 'today');
  });
}
