import 'package:drift/native.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/components/ask_sheet.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/components/settings_button.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/database/database.dart';
import 'package:quotely_flutter_app/navigation/routes.dart';
import 'package:quotely_flutter_app/screens/search_screen.dart';
import 'package:quotely_flutter_app/screens/tab_screens/facts_screen.dart';
import 'package:quotely_flutter_app/screens/tab_screens/home_screen.dart';
import 'package:quotely_flutter_app/screens/tab_screens/people_screen.dart';
import 'package:quotely_flutter_app/screens/tab_screens/saved_screen.dart';
import 'package:quotely_flutter_app/screens/tab_screens/scenes_screen.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';
import 'package:quotely_flutter_app/services/drift_scene_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records analytics events instead of sending them.
class _FakeAnalytics implements FirebaseAnalytics {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    List<AnalyticsEventItem>? items,
    AnalyticsCallOptions? callOptions,
  }) async => events.add((name, parameters));

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

late _FakeAnalytics _analytics;

/// Terms already accepted, so Today opens without the consent sheet; the
/// bundled Scenes seed counts as loaded, so no test waits on importing it.
const _prefs = <String, Object>{
  kAcceptedLegalVersionKey: kCurrentLegalVersion,
  'scenes-seed-loaded-v1': true,
};

const _youScreen = Key('you-screen');

/// [screen] at `/`, with You and Search as stub routes, in the real theme.
Widget _app(Widget screen) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: screen),
      ),
      GoRoute(
        path: Routes.you,
        builder: (_, _) => const Scaffold(body: SizedBox(key: _youScreen)),
      ),
      GoRoute(
        path: Routes.search,
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
      routerConfig: router,
    ),
  );
}

/// Pumps a few frames: enough for local loads to settle without waiting
/// on animations that never end (skeleton shimmer).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Unmounts the screen and lets its pending timers run out.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

Iterable<(String, Map<String, Object>?)> _opened() =>
    _analytics.events.where((e) => e.$1 == 'composer_opened');

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({..._prefs});
    _analytics = _FakeAnalytics();
    getIt.registerSingleton<FirebaseAnalytics>(_analytics);
    // A fresh in-memory database per test, so no test inherits another's
    // unfinished queries.
    getIt.registerSingleton<AppDatabase>(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    // Scenes share one seeding future for the whole run. Finish it here,
    // outside any test's fake clock, so no test waits on another's.
    await DriftSceneService.ensureSeeded();
  });

  tearDown(() => getIt.reset(dispose: false));

  group('Settings button', () {
    testWidgets('opens Settings', (tester) async {
      await tester.pumpWidget(_app(const Center(child: SettingsButton())));
      await tester.pump();
      expect(
        find.bySemanticsLabel(SettingsButton.semanticLabel),
        findsOneWidget,
      );
      await tester.tap(find.byType(SettingsButton));
      await tester.pumpAndSettle();
      expect(find.byKey(_youScreen), findsOneWidget);
    });

    testWidgets('is a gear, not an avatar', (tester) async {
      await tester.pumpWidget(_app(const Center(child: SettingsButton())));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(SettingsButton),
          matching: find.byIcon(Icons.settings_outlined),
        ),
        findsOneWidget,
      );
    });

    final tabs = <String, Widget Function()>{
      'Today': () => const HomeScreen(),
      'Scenes': () => const ScenesScreen(),
      'Saved': () => const SavedScreen(),
      'People': () => const PeopleScreen(),
      'Facts': () => const FactsScreen(),
    };
    for (final MapEntry(key: name, value: build) in tabs.entries) {
      testWidgets('is in the $name header and opens Settings', (tester) async {
        await tester.pumpWidget(_app(build()));
        await _settle(tester);
        final avatar = find.byType(SettingsButton);
        expect(avatar, findsOneWidget);
        // Top right, like Today's.
        final rect = tester.getRect(avatar);
        final screen = tester.getSize(find.byType(Scaffold).first);
        expect(rect.center.dx, greaterThan(screen.width * 0.8));
        expect(rect.top, lessThan(140));

        await tester.tap(avatar);
        await _settle(tester);
        expect(find.byKey(_youScreen), findsOneWidget);
        await _teardown(tester);
      });
    }
  });

  group('Ask entry points', () {
    Future<void> expectSheet(WidgetTester tester, {String? prefill}) async {
      await _settle(tester);
      expect(find.byType(AskSheet), findsOneWidget);
      expect(find.text('Ask for a line'), findsOneWidget);
      if (prefill != null) {
        final field = tester.widget<TextField>(
          find.descendant(
            of: find.byType(Composer),
            matching: find.byType(TextField),
          ),
        );
        expect(field.controller!.text, prefill);
      }
    }

    testWidgets('openAskSheet logs its source and prefills', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => openAskSheet(
                  context,
                  source: AskSource.todayRail,
                  prefill: '  courage ',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await expectSheet(tester, prefill: 'courage');
      expect(_opened().single.$2, {'source': 'today_rail'});
    });

    Future<void> search(WidgetTester tester, String query) async {
      await tester.pumpWidget(_app(const SearchScreen()));
      await tester.pump();
      await tester.enterText(find.byType(TextField), query);
      await tester.pump(const Duration(milliseconds: 500));
      // People and titles go to the backend first; let that real I/O
      // fail (no network in tests) so the screen settles on local data.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('search: the prompt under the field carries the query', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const SearchScreen()));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'hope');
      // Past the debounce: shown while searching and over the results.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Ask for a line about “hope”'));
      await expectSheet(tester, prefill: 'hope');
      expect(_opened().single.$2, {'source': 'search'});
      await _teardown(tester);
    });

    testWidgets('search: no results offer Ask with the query', (tester) async {
      await search(tester, 'zzyzx');
      expect(find.text('Nothing for “zzyzx”'), findsOneWidget);
      await tester.tap(find.text('Can’t find it? Ask for a line'));
      await expectSheet(tester, prefill: 'zzyzx');
      expect(_opened().single.$2, {'source': 'empty_state'});
      await _teardown(tester);
    });

    testWidgets('search: the idle link opens Ask from search', (tester) async {
      await tester.pumpWidget(_app(const SearchScreen()));
      await tester.pump();
      await tester.tap(find.text('Or ask for a line'));
      await expectSheet(tester);
      expect(_opened().single.$2, {'source': 'search'});
      await _teardown(tester);
    });

    testWidgets('today: Ask in the rail', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen()));
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Ask'));
      await expectSheet(tester);
      expect(_opened().single.$2, {'source': 'today_rail'});
      await _teardown(tester);
    });

    testWidgets('scenes: Ask in the Watch rail', (tester) async {
      await tester.pumpWidget(_app(const ScenesScreen()));
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Ask'));
      await expectSheet(tester);
      expect(_opened().single.$2, {'source': 'scenes'});
      await _teardown(tester);
    });

    testWidgets('saved: the empty state asks for a line', (tester) async {
      await tester.pumpWidget(_app(const SavedScreen()));
      await _settle(tester);
      expect(find.text('Nothing saved yet'), findsOneWidget);
      await tester.tap(find.text('Or ask for a line to keep'));
      await expectSheet(tester);
      expect(_opened().single.$2, {'source': 'empty_state'});
      await _teardown(tester);
    });

    testWidgets('the prompt link opens Ask with its prefill', (tester) async {
      await tester.pumpWidget(
        _app(const Center(child: AskForALinePrompt(prefill: 'Mandela'))),
      );
      await tester.pump();
      await tester.tap(find.text('Can’t find it? Ask for a line'));
      await expectSheet(tester, prefill: 'Mandela');
      expect(_opened().single.$2, {'source': 'empty_state'});
    });
  });
}
