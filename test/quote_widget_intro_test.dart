import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/quote_widget_intro.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/dtos/quote_of_the_day_dto.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:quotely_flutter_app/riverpods/today_quote_of_the_day_provider.dart';
import 'package:quotely_flutter_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('home_widget');

final _quote = QuoteOfTheDayDto(
  quoteOfTheDayId: 1,
  quoteDate: DateTime.utc(2026, 10, 28),
  quoteId: 'q',
  author: 'Maya Angelou',
  content: 'Nothing will work unless you do.',
  tags: const [],
  authorSlug: 'maya-angelou',
  length: 32,
  quoteDateAdded: DateTime.utc(2026),
  quoteDateModified: DateTime.utc(2026),
);

/// Onboarding finished (the router's three gates) plus [extra].
Map<String, Object> _prefs([Map<String, Object> extra = const {}]) => {
  'onboardingShown': true,
  kHasSelectedInterestsKey: true,
  kHasSeenNotificationPrompt: true,
  ...extra,
};

/// A stand-in Today with buttons that run what Today and You run.
Widget _host() => ProviderScope(
  overrides: [
    fetchTodayQuoteOfTheDayProvider.overrideWith((ref) async => _quote),
    sceneOfTheDayProvider.overrideWith((ref) async => null),
  ],
  child: MaterialApp(
    theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
    home: Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            TextButton(
              onPressed: () => maybeShowQuoteWidgetIntro(context),
              child: const Text('open app'),
            ),
            TextButton(
              onPressed: () => addQuoteWidget(context),
              child: const Text('settings row'),
            ),
          ],
        ),
      ),
    ),
  ),
);

/// Answers home_widget's channel; records the calls.
List<String> _mockPlugin({required bool pinSupported}) {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
        calls.add(call.method);
        if (call.method == 'isRequestPinWidgetSupported') return pinSupported;
        return null;
      });
  return calls;
}

Future<void> _openApp(WidgetTester tester) async {
  await tester.tap(find.text('open app'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(QuoteWidgetIntro.debugReset);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('introduction', () {
    testWidgets('shows once, from the second open, after onboarding', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_prefs({kAppOpenCountKey: 1}));
      await tester.pumpWidget(_host());
      await _openApp(tester);

      expect(
        find.text("Put today's quote on your home screen"),
        findsOneWidget,
      );
      expect(find.text('Add widget'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      // The preview uses today's quote.
      expect(find.text('Nothing will work unless you do.'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kQuoteWidgetIntroShownKey), isTrue);
      expect(prefs.getInt(kAppOpenCountKey), 2);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text("Put today's quote on your home screen"), findsNothing);
      // "Not now" doesn't go on to the instructions.
      expect(find.text('Add the widget'), findsNothing);
    });

    testWidgets('does not interrupt a first-ever launch', (tester) async {
      SharedPreferences.setMockInitialValues(_prefs());
      await tester.pumpWidget(_host());
      await _openApp(tester);

      expect(find.text("Put today's quote on your home screen"), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(kAppOpenCountKey), 1);
      expect(prefs.getBool(kQuoteWidgetIntroShownKey), isNull);
    });

    testWidgets('counts one open per run, not per visit to Today', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_prefs());
      await tester.pumpWidget(_host());
      await _openApp(tester);
      await _openApp(tester);

      expect(find.text("Put today's quote on your home screen"), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(kAppOpenCountKey), 1);
    });

    testWidgets('never during onboarding', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboardingShown': true,
        kHasSelectedInterestsKey: true,
        // Notification prompt not seen yet.
        kAppOpenCountKey: 5,
      });
      await tester.pumpWidget(_host());
      await _openApp(tester);

      expect(find.text("Put today's quote on your home screen"), findsNothing);
    });

    testWidgets('not again once shown', (tester) async {
      SharedPreferences.setMockInitialValues(
        _prefs({kAppOpenCountKey: 3, kQuoteWidgetIntroShownKey: true}),
      );
      await tester.pumpWidget(_host());
      await _openApp(tester);

      expect(find.text("Put today's quote on your home screen"), findsNothing);
    });

    testWidgets('Add widget pins it where the launcher supports pinning', (
      tester,
    ) async {
      final calls = _mockPlugin(pinSupported: true);
      SharedPreferences.setMockInitialValues(_prefs({kAppOpenCountKey: 1}));
      await tester.pumpWidget(_host());
      await _openApp(tester);
      await tester.tap(find.text('Add widget'));
      await tester.pumpAndSettle();

      expect(calls, ['isRequestPinWidgetSupported', 'requestPinWidget']);
      expect(find.text('Add the widget'), findsNothing);
    });
  });

  group('instructions sheet', () {
    testWidgets('Android without pinning: long-press, Widgets, Quotely', (
      tester,
    ) async {
      final calls = _mockPlugin(pinSupported: false);
      SharedPreferences.setMockInitialValues(_prefs());
      await tester.pumpWidget(_host());
      await tester.tap(find.text('settings row'));
      await tester.pumpAndSettle();

      expect(calls, ['isRequestPinWidgetSupported']);
      expect(find.text('Add the widget'), findsOneWidget);
      expect(
        find.text('Touch and hold an empty spot on your home screen.'),
        findsOneWidget,
      );
      expect(find.text('Tap Widgets.'), findsOneWidget);
      expect(
        find.textContaining('Find Quotely', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Add the widget'), findsNothing);
    });

    testWidgets('iOS: no programmatic add, straight to the steps', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final calls = _mockPlugin(pinSupported: true);
      SharedPreferences.setMockInitialValues(_prefs());
      await tester.pumpWidget(_host());
      await tester.tap(find.text('settings row'));
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
      expect(find.text('Add the widget'), findsOneWidget);
      expect(find.textContaining('until the apps'), findsOneWidget);
      expect(find.textContaining('Search for Quotely'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
