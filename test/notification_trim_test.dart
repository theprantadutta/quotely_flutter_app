import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/notification_trim_sheet.dart';
import 'package:quotely_flutter_app/constants/notification_keys.dart';
import 'package:quotely_flutter_app/constants/notification_types.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
import 'package:quotely_flutter_app/services/notification_trim.dart';
import 'package:quotely_flutter_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records topic calls instead of talking to FCM.
class _Topics {
  final subscribed = <String>{};
  final unsubscribed = <String>{};

  NotificationService get service => NotificationService(
    subscribe: (t) async => subscribed.add(t),
    unsubscribe: (t) async => unsubscribed.add(t),
  );
}

/// An install from before 3.2.0 that finished onboarding with every kind on.
Map<String, Object> _oldInstallAllOn([Map<String, Object> extra = const {}]) =>
    {
      kInstallCohortKey: 'existing',
      kNotificationDefaultsKey: 'legacy',
      kOnboardingShownKey: true,
      kHasSelectedInterestsKey: true,
      kHasSeenNotificationPrompt: true,
      kNotificationsInitializedKey: true,
      kNotificationEnabled: true,
      for (final t in kNotificationTypes) t.prefKey: true,
      ...extra,
    };

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  group('who is asked', () {
    test('an old install with every kind on', () async {
      expect(
        NotificationTrim.shouldOffer(await _prefs(_oldInstallAllOn())),
        isTrue,
      );
    });

    test(
      'an old install that never stored the newer kinds (they read as on)',
      () async {
        final prefs = await _prefs({
          kInstallCohortKey: 'existing',
          kNotificationDefaultsKey: 'legacy',
          kOnboardingShownKey: true,
          kHasSeenNotificationPrompt: true,
          kNotificationQuoteOfTheDay: true,
          kNotificationFactOfTheDay: false,
        });
        expect(NotificationTrim.enabledCount(prefs), greaterThan(2));
        expect(NotificationTrim.shouldOffer(prefs), isTrue);
      },
    );

    test('not a new install', () async {
      final prefs = await _prefs(
        _oldInstallAllOn({
          kInstallCohortKey: 'new',
          kNotificationDefaultsKey: 'calm',
        }),
      );
      expect(NotificationTrim.shouldOffer(prefs), isFalse);
    });

    test(
      'not a 3.2/3.3 install, which started calm and chose its kinds',
      () async {
        final prefs = await _prefs(
          _oldInstallAllOn({kNotificationDefaultsKey: 'calm'}),
        );
        expect(NotificationTrim.shouldOffer(prefs), isFalse);
      },
    );

    test('not with two kinds or fewer on', () async {
      final prefs = await _prefs(
        _oldInstallAllOn({
          for (final t in kNotificationTypes) t.prefKey: false,
          kNotificationQuoteOfTheDay: true,
          kNotificationFactOfTheDay: true,
        }),
      );
      expect(NotificationTrim.enabledCount(prefs), 2);
      expect(NotificationTrim.shouldOffer(prefs), isFalse);
    });

    test('not with notifications switched off', () async {
      final prefs = await _prefs(
        _oldInstallAllOn({kNotificationEnabled: false}),
      );
      expect(NotificationTrim.shouldOffer(prefs), isFalse);
    });

    test('not twice', () async {
      final prefs = await _prefs(
        _oldInstallAllOn({kNotificationTrimShownKey: true}),
      );
      expect(NotificationTrim.shouldOffer(prefs), isFalse);
    });
  });

  test(
    'keep just one: Quote of the day stays, the rest go, in prefs and FCM',
    () async {
      final prefs = await _prefs(
        _oldInstallAllOn({kFollowedTitleSlugsKey: '{"1":"the-godfather"}'}),
      );
      final topics = _Topics();
      await NotificationTrim.keepJustQuoteOfTheDay(prefs, topics.service);

      for (final t in kNotificationTypes) {
        expect(
          prefs.getBool(t.prefKey),
          t.prefKey == kNotificationQuoteOfTheDay,
          reason: t.title,
        );
      }
      expect(prefs.getBool(kNotificationEnabled), isTrue);
      expect(topics.subscribed, {
        kNotificationQuoteOfTheDayTopic,
        kNotificationAllTopic,
      });
      expect(topics.unsubscribed, {
        for (final t in kNotificationTypes)
          if (t.topic != null && t.prefKey != kNotificationQuoteOfTheDay)
            t.topic!,
        '${kNotificationTitleTopicPrefix}the-godfather',
      });
      expect(NotificationTrim.enabledCount(prefs), 1);
    },
  );

  group('sheet', () {
    late _Topics topics;
    late List<String> chose;

    Future<void> open(WidgetTester tester) async {
      topics = _Topics();
      chose = [];
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildQuotelyTheme(
            Brightness.light,
            const AppearanceSettings(),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => maybeOfferNotificationTrim(
                  context,
                  isCalm: () => true,
                  service: topics.service,
                  onChoose: (_) => chose.add('settings'),
                  settle: Duration.zero,
                ),
                child: const Text('today loaded'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('today loaded'));
      await tester.pumpAndSettle();
    }

    testWidgets('Keep just one applies the trim', (tester) async {
      SharedPreferences.setMockInitialValues(_oldInstallAllOn());
      await open(tester);

      expect(find.text('Too many notifications?'), findsOneWidget);
      expect(find.text('Keep just one'), findsOneWidget);
      expect(find.text('Choose'), findsOneWidget);
      expect(find.text('Keep all'), findsOneWidget);

      await tester.tap(find.text('Keep just one'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(NotificationTrim.enabledCount(prefs), 1);
      expect(prefs.getBool(kNotificationQuoteOfTheDay), isTrue);
      expect(prefs.getBool(kNotificationTrimShownKey), isTrue);
      expect(topics.unsubscribed, contains(kNotificationDailyInspirationTopic));
    });

    testWidgets('Choose opens notification settings and changes nothing', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_oldInstallAllOn());
      await open(tester);
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();

      expect(chose, ['settings']);
      final prefs = await SharedPreferences.getInstance();
      expect(NotificationTrim.enabledCount(prefs), kNotificationTypes.length);
      expect(topics.unsubscribed, isEmpty);
    });

    testWidgets('Keep all changes nothing, and it is never asked again', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_oldInstallAllOn());
      await open(tester);
      await tester.tap(find.text('Keep all'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(NotificationTrim.enabledCount(prefs), kNotificationTypes.length);
      expect(topics.subscribed, isEmpty);
      expect(topics.unsubscribed, isEmpty);

      await tester.tap(find.text('today loaded'));
      await tester.pumpAndSettle();
      expect(find.text('Too many notifications?'), findsNothing);
    });

    testWidgets('a new install never sees it', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await NotificationService.resolveDefaults();
      final prefs = await SharedPreferences.getInstance();
      for (final t in kNotificationTypes) {
        await prefs.setBool(t.prefKey, true);
      }
      await prefs.setBool(kHasSeenNotificationPrompt, true);
      await open(tester);
      expect(find.text('Too many notifications?'), findsNothing);
    });

    testWidgets('waits while another sheet is up', (tester) async {
      SharedPreferences.setMockInitialValues(_oldInstallAllOn());
      topics = _Topics();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildQuotelyTheme(
            Brightness.light,
            const AppearanceSettings(),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    useRootNavigator: true,
                    builder: (_) => const Text('another sheet'),
                  );
                  maybeOfferNotificationTrim(
                    context,
                    isCalm: () => true,
                    service: topics.service,
                    settle: Duration.zero,
                    retryEvery: const Duration(seconds: 1),
                    attempts: 2,
                  );
                },
                child: const Text('today loaded'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('today loaded'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('another sheet'), findsOneWidget);
      expect(find.text('Too many notifications?'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      // Not shown, so still to come on a later visit.
      expect(prefs.getBool(kNotificationTrimShownKey), isNull);
    });
  });
}
