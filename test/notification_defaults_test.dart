import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:quotely_flutter_app/constants/notification_keys.dart';
import 'package:quotely_flutter_app/constants/notification_types.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/screens/notifications_onboarding_screen.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
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

/// What a user who finished onboarding on 3.1.1 has stored: every kind
/// written explicitly, some switched off.
Map<String, Object> _finishedOnboardingOnOldVersion() => {
  kOnboardingShownKey: true,
  kHasSelectedInterestsKey: true,
  kHasSeenNotificationPrompt: true,
  kNotificationsInitializedKey: true,
  kNotificationEnabled: true,
  for (final t in kNotificationTypes) t.prefKey: true,
  kNotificationDailyInspiration: false,
  kNotificationWeirdFactWednesday: false,
};

/// An install from before the notifications primer: seeded all-on by an
/// older version, and never stored the kinds added since.
Map<String, Object> _preRedesignInstall() => {
  kOnboardingShownKey: true,
  kNotificationsInitializedKey: true,
  kNotificationEnabled: true,
  kNotificationMotivation: true,
  kNotificationDailyInspiration: true,
  kNotificationQuoteOfTheDay: true,
  kNotificationFactOfTheDay: false,
  kNotificationDailyBrainFood: true,
  kNotificationWeirdFactWednesday: true,
};

Set<String> _fixedTopics(bool Function(NotificationType) on) => {
  for (final t in kNotificationTypes)
    if (t.topic != null && on(t)) t.topic!,
};

void main() {
  group('new installs start calm', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('only Quote of the day is on; the decision is stored', () async {
      await NotificationService.resolveDefaults();
      final prefs = await SharedPreferences.getInstance();

      expect(NotificationService.usesCalmDefaults(prefs), isTrue);
      expect(prefs.getString(kNotificationDefaultsKey), 'calm');
      for (final t in kNotificationTypes) {
        expect(
          NotificationService.isEnabled(prefs, t.prefKey),
          t.prefKey == kNotificationQuoteOfTheDay,
          reason: t.title,
        );
      }
      expect(NotificationService.isEnabled(prefs, kNotificationEnabled), true);
    });

    test('stays calm once onboarding starts writing prefs', () async {
      await NotificationService.resolveDefaults();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingShownKey, true);
      await prefs.setBool(kHasSelectedInterestsKey, true);

      expect(NotificationService.usesCalmDefaults(prefs), isTrue);
    });

    test(
      'first-launch setup seeds calm prefs and subscribes to one topic',
      () async {
        await NotificationService.resolveDefaults();
        final topics = _Topics();
        await topics.service.initializeNotificationPreferencesOnce();
        final prefs = await SharedPreferences.getInstance();

        expect(topics.subscribed, {kNotificationQuoteOfTheDayTopic});
        expect(topics.unsubscribed, isEmpty);
        expect(prefs.getBool(kNotificationQuoteOfTheDay), isTrue);
        expect(prefs.getBool(kNotificationDailyInspiration), isFalse);
        expect(prefs.getBool(kNotificationFollowedTitles), isFalse);
        expect(prefs.getBool(kNotificationEnabled), isTrue);
      },
    );
  });

  group('existing users keep exactly what they have', () {
    for (final (label, stored) in [
      ('finished onboarding on 3.1.1', _finishedOnboardingOnOldVersion()),
      ('pre-redesign install', _preRedesignInstall()),
    ]) {
      group(label, () {
        setUp(() => SharedPreferences.setMockInitialValues(stored));

        test('stored values win; missing kinds read as on', () async {
          await NotificationService.resolveDefaults();
          final prefs = await SharedPreferences.getInstance();

          expect(NotificationService.usesCalmDefaults(prefs), isFalse);
          expect(prefs.getString(kNotificationDefaultsKey), 'legacy');
          for (final t in kNotificationTypes) {
            final value = stored[t.prefKey] as bool?;
            expect(
              NotificationService.isEnabled(prefs, t.prefKey),
              value ?? true,
              reason: t.title,
            );
          }
        });

        test('upgrade launch changes no stored pref and keeps today\'s '
            'subscriptions', () async {
          await NotificationService.resolveDefaults();
          final topics = _Topics();
          await topics.service.initializeNotificationPreferencesOnce();
          final prefs = await SharedPreferences.getInstance();

          for (final entry in stored.entries) {
            expect(prefs.get(entry.key), entry.value, reason: entry.key);
          }
          // Same rule the previous version applied: stored ?? true.
          expect(
            topics.subscribed,
            _fixedTopics((t) => stored[t.prefKey] as bool? ?? true),
          );
          expect(topics.unsubscribed, isEmpty);
        });
      });
    }

    test('without a defaults marker, any stored notification pref means '
        'legacy', () async {
      SharedPreferences.setMockInitialValues({
        kNotificationFridayNightLines: false,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(NotificationService.usesCalmDefaults(prefs), isFalse);
      expect(
        NotificationService.isEnabled(prefs, kNotificationFactOfTheDay),
        isTrue,
      );
    });

    test('a stored marker is never re-decided', () async {
      SharedPreferences.setMockInitialValues({
        kNotificationDefaultsKey: 'calm',
        kNotificationsInitializedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(NotificationService.usesCalmDefaults(prefs), isTrue);
    });
  });

  group('onboarding screen', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sceneOfTheDayProvider.overrideWith((ref) async => null)],
          child: MaterialApp(
            theme: buildQuotelyTheme(
              Brightness.light,
              const AppearanceSettings(),
            ),
            home: const NotificationsOnboardingScreen(),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    bool toggle(WidgetTester tester, String title) => tester
        .widget<QToggle>(
          find.byWidgetPredicate(
            (w) => w is QToggle && w.semanticLabel == title,
          ),
        )
        .value;

    testWidgets('a new install sees one kind on and the others to opt into', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await NotificationService.resolveDefaults();
      await pump(tester);

      expect(
        find.text(
          'Start with one a day. Add more anytime in You → Notifications.',
        ),
        findsOneWidget,
      );
      for (final t in kNotificationTypes.where((t) => t.inPrimer)) {
        expect(
          toggle(tester, t.title),
          t.prefKey == kNotificationQuoteOfTheDay,
          reason: t.title,
        );
      }
    });

    testWidgets('an upgrading user who never saw it keeps everything on', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_preRedesignInstall());
      await NotificationService.resolveDefaults();
      await pump(tester);

      expect(
        find.text('Change these anytime in You → Notifications.'),
        findsOneWidget,
      );
      expect(toggle(tester, 'Fact of the day'), isFalse);
      expect(toggle(tester, 'Daily inspiration'), isTrue);
      expect(toggle(tester, 'Friday night lines'), isTrue);
    });
  });
}
