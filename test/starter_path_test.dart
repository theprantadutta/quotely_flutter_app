import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/starter_path_card.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/navigation/screen_tracking.dart';
import 'package:quotely_flutter_app/services/app_analytics.dart';
import 'package:quotely_flutter_app/services/install_cohort.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
import 'package:quotely_flutter_app/services/starter_path.dart';
import 'package:quotely_flutter_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A clock the test moves forward a day at a time.
class _Clock {
  DateTime now = DateTime(2026, 11, 17, 9);
  void nextDay() => now = now.add(const Duration(days: 1));
}

/// A starter path for a new install, listening to [events].
Future<(StarterPath, _Clock, StreamController<AppEvent>)> _newInstall({
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({kInstallCohortKey: 'new', ...prefs});
  final clock = _Clock();
  final events = StreamController<AppEvent>.broadcast();
  final path = StarterPath(clock: () => clock.now);
  await path.attach(
    await SharedPreferences.getInstance(),
    events: events.stream,
  );
  return (path, clock, events);
}

/// The same install, opened again (state read back from prefs).
Future<StarterPath> _reopen(_Clock clock) async {
  final path = StarterPath(clock: () => clock.now);
  await path.attach(
    await SharedPreferences.getInstance(),
    events: const Stream.empty(),
  );
  return path;
}

void main() {
  group('install cohort', () {
    test('a clean install is new', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await InstallCohort.resolve(prefs);
      expect(InstallCohort.isNew(prefs), isTrue);
      expect(InstallCohort.isExisting(prefs), isFalse);
    });

    test('an install that ran an older version is existing', () async {
      SharedPreferences.setMockInitialValues({kOnboardingShownKey: true});
      final prefs = await SharedPreferences.getInstance();
      await InstallCohort.resolve(prefs);
      expect(InstallCohort.isExisting(prefs), isTrue);
    });

    test(
      'a 3.2/3.3 install (calm notification defaults) is existing',
      () async {
        SharedPreferences.setMockInitialValues({
          kNotificationDefaultsKey: 'calm',
          kOnboardingShownKey: true,
          kHasSelectedInterestsKey: true,
        });
        final prefs = await SharedPreferences.getInstance();
        await InstallCohort.resolve(prefs);
        expect(InstallCohort.isExisting(prefs), isTrue);
      },
    );

    test(
      'main() settles it before onboarding writes, and it never changes',
      () async {
        SharedPreferences.setMockInitialValues({});
        // What main() runs first; it also writes notification-defaults.
        await NotificationService.resolveDefaults();
        final prefs = await SharedPreferences.getInstance();
        expect(InstallCohort.isNew(prefs), isTrue);

        // Onboarding then writes what an old install has.
        await prefs.setBool(kOnboardingShownKey, true);
        await NotificationService.resolveDefaults();
        await InstallCohort.resolve(prefs);
        expect(InstallCohort.isNew(prefs), isTrue);
      },
    );
  });

  group('progression', () {
    test('one step a day, each ticking off when it happens', () async {
      final (path, clock, _) = await _newInstall();

      // Day 1: save.
      expect(path.day, 1);
      expect(path.visibleStep, StarterStep.save);
      await path.onEvent('favorite_toggled', {
        'kind': 'quote',
        'saved': 'true',
      });
      expect(path.isDone(StarterStep.save), isTrue);
      // Stays up, ticked, for the rest of the day.
      expect(path.visibleStep, StarterStep.save);

      // Day 2: True or False.
      clock.nextDay();
      await path.recordActiveDay();
      expect(path.day, 2);
      expect(path.visibleStep, StarterStep.trueFalse);
      await path.onEvent('facts_game_answered', const {});
      expect(path.isDone(StarterStep.trueFalse), isTrue);

      // Day 3: Scenes, then the path is over.
      clock.nextDay();
      await path.recordActiveDay();
      expect(path.visibleStep, StarterStep.scenes);
      await path.onEvent('screen_view', {'screen_name': 'scenes'});
      expect(path.allDone, isTrue);
      expect(path.finished, isTrue);
      expect(path.visibleStep, isNull);
    });

    test('unsaving and other screens do not count', () async {
      final (path, _, _) = await _newInstall();
      await path.onEvent('favorite_toggled', {
        'kind': 'quote',
        'saved': 'false',
      });
      await path.onEvent('screen_view', {'screen_name': 'today'});
      await path.onEvent('content_shared', {'kind': 'quote'});
      expect(path.isDone(StarterStep.save), isFalse);
      expect(path.isDone(StarterStep.scenes), isFalse);
    });

    test(
      'days count only when the app is opened, not by the calendar',
      () async {
        final (path, clock, _) = await _newInstall();
        clock.nextDay();
        clock.nextDay();
        clock.nextDay();
        await path.recordActiveDay();
        expect(path.day, 2);
        expect(path.visibleStep, StarterStep.trueFalse);
      },
    );

    test('a step done early leaves no card on its own day', () async {
      final (path, clock, _) = await _newInstall();
      await path.onEvent('screen_view', {'screen_name': 'scenes'});
      expect(path.visibleStep, StarterStep.save);

      clock.nextDay();
      await path.recordActiveDay();
      clock.nextDay();
      await path.recordActiveDay();
      expect(path.day, 3);
      expect(path.visibleStep, isNull);
    });

    test('a fourth active day ends it for good', () async {
      final (path, clock, _) = await _newInstall();
      for (var i = 0; i < 3; i++) {
        clock.nextDay();
        await path.recordActiveDay();
      }
      expect(path.finished, isTrue);
      expect(path.visibleStep, isNull);
      // Doing a step now changes nothing.
      await path.onEvent('facts_game_answered', const {});
      expect(path.isDone(StarterStep.trueFalse), isFalse);

      final again = await _reopen(clock);
      expect(again.finished, isTrue);
      expect(again.visibleStep, isNull);
    });

    test('a dismissed card stays gone, also after a restart', () async {
      final (path, clock, _) = await _newInstall();
      await path.dismiss(StarterStep.save);
      expect(path.visibleStep, isNull);

      final again = await _reopen(clock);
      expect(again.visibleStep, isNull);
      // The next day's card still comes.
      clock.nextDay();
      await again.recordActiveDay();
      expect(again.visibleStep, StarterStep.trueFalse);
    });

    test('progress survives a restart', () async {
      final (path, clock, _) = await _newInstall();
      await path.onEvent('favorite_toggled', {'saved': 'true'});
      clock.nextDay();
      final again = await _reopen(clock);
      expect(again.isDone(StarterStep.save), isTrue);
      expect(again.day, 2);
      final stored = jsonDecode(
        (await SharedPreferences.getInstance()).getString(kStarterPathKey)!,
      );
      expect((stored as Map)['days'], hasLength(2));
    });

    test('never for installs from before this version', () async {
      SharedPreferences.setMockInitialValues({
        kInstallCohortKey: 'existing',
        kOnboardingShownKey: true,
      });
      final path = StarterPath(clock: () => DateTime(2026, 11, 17));
      await path.attach(
        await SharedPreferences.getInstance(),
        events: const Stream.empty(),
      );
      expect(path.visibleStep, isNull);
      await path.onEvent('favorite_toggled', {'saved': 'true'});
      expect(path.isDone(StarterStep.save), isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString(kStarterPathKey),
        isNull,
      );
    });

    test('hears the app\'s own analytics events, without Firebase', () async {
      SharedPreferences.setMockInitialValues({kInstallCohortKey: 'new'});
      final path = StarterPath(clock: () => DateTime(2026, 11, 17, 9));
      await path.attach(await SharedPreferences.getInstance());
      addTearDown(path.debugDetach);

      logAppEvent('favorite_toggled', {'kind': 'scene', 'saved': 'true'});
      AppEvents.emit('facts_game_answered');
      ScreenAnalytics.log(ScreenNames.scenes);
      await pumpEventQueue();

      expect(path.allDone, isTrue);
    });
  });

  group('card', () {
    late _Clock clock;

    Future<StarterPath> pumpCard(
      WidgetTester tester, {
      List<StarterStep>? actions,
    }) async {
      final (path, c, _) = await _newInstall();
      clock = c;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildQuotelyTheme(
            Brightness.light,
            const AppearanceSettings(),
          ),
          home: Scaffold(
            body: Column(
              children: [StarterPathCard(path: path, onAction: actions?.add)],
            ),
          ),
        ),
      );
      return path;
    }

    testWidgets('day 1 asks to save, ticks off, and can be dismissed', (
      tester,
    ) async {
      final path = await pumpCard(tester);
      expect(find.text('Save a line you love.'), findsOneWidget);
      expect(find.text('DAY 1 OF 3 · GETTING STARTED'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      await tester.runAsync(
        () => path.onEvent('favorite_toggled', {'saved': 'true'}),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(
        find.text('Saved. It’s waiting for you in Saved.'),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Save a line you love.'), findsNothing);
    });

    testWidgets('day 2 offers True or False, day 3 Scenes', (tester) async {
      final actions = <StarterStep>[];
      final path = await pumpCard(tester, actions: actions);

      clock.nextDay();
      await tester.runAsync(path.recordActiveDay);
      await tester.pumpAndSettle();
      expect(find.text('Save a line you love.'), findsNothing);
      expect(find.text('Try today’s True or False.'), findsOneWidget);
      await tester.tap(find.text('Play'));
      expect(actions, [StarterStep.trueFalse]);

      clock.nextDay();
      await tester.runAsync(path.recordActiveDay);
      await tester.pumpAndSettle();
      expect(find.text('Find a line from a film you love'), findsOneWidget);
      await tester.tap(find.text('Open Scenes'));
      expect(actions, [StarterStep.trueFalse, StarterStep.scenes]);
    });
  });
}
