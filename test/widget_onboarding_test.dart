import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/components/quote_widget_intro.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/navigation/routes.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:quotely_flutter_app/riverpods/today_quote_of_the_day_provider.dart';
import 'package:quotely_flutter_app/screens/notifications_onboarding_screen.dart';
import 'package:quotely_flutter_app/screens/widget_onboarding_screen.dart';
import 'package:quotely_flutter_app/services/home_widget_store.dart';
import 'package:quotely_flutter_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding's notifications and widget steps, and a stand-in Today that
/// runs what Today runs on open.
Widget _app({required String initial, List<QuotelyWidgetKind>? added}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: Routes.notificationsOnboarding,
        builder: (_, _) => const NotificationsOnboardingScreen(),
      ),
      GoRoute(
        path: Routes.widgetOnboarding,
        builder: (_, _) =>
            WidgetOnboardingScreen(onAdd: (_, kind) async => added?.add(kind)),
      ),
      GoRoute(
        path: Routes.today,
        builder: (_, _) => Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('TODAY'),
                TextButton(
                  onPressed: () => maybeShowQuoteWidgetIntro(context),
                  child: const Text('open app'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      // Offline: the previews fall back to their sample lines.
      fetchTodayQuoteOfTheDayProvider.overrideWith(
        (ref) => Future.error('offline'),
      ),
      sceneOfTheDayProvider.overrideWith((ref) async => null),
    ],
    child: MaterialApp.router(
      theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
      routerConfig: router,
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A new install that reached the notifications step.
Map<String, Object> _inOnboarding([Map<String, Object> extra = const {}]) => {
  kInstallCohortKey: 'new',
  kOnboardingShownKey: true,
  kHasSelectedInterestsKey: true,
  ...extra,
};

void main() {
  setUp(QuoteWidgetIntro.debugReset);

  Future<void> pump(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await _settle(tester);
  }

  testWidgets('the notifications step continues to the widget step', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_inOnboarding());
    await pump(tester, _app(initial: Routes.notificationsOnboarding));
    expect(find.text('Step 3 of 4'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await _settle(tester);

    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(find.text('Put Quotely on your home screen'), findsOneWidget);
    // The live preview, with the three to choose from.
    expect(
      find.bySemanticsLabel('Quote of the Day widget preview'),
      findsWidgets,
    );
    expect(find.text('From your saved'), findsOneWidget);
    expect(find.text('Scene of the Day'), findsOneWidget);
  });

  testWidgets('skipping goes to Today and retires the intro there', (
    tester,
  ) async {
    // The next open would be the second, when the intro normally shows.
    SharedPreferences.setMockInitialValues(
      _inOnboarding({kHasSeenNotificationPrompt: true, kAppOpenCountKey: 1}),
    );
    final added = <QuotelyWidgetKind>[];
    await pump(tester, _app(initial: Routes.widgetOnboarding, added: added));

    await tester.tap(find.text('Not now'));
    await _settle(tester);

    expect(find.text('TODAY'), findsOneWidget);
    expect(added, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kQuoteWidgetIntroShownKey), isTrue);

    await tester.tap(find.text('open app'));
    await _settle(tester);
    expect(find.text('Add widget'), findsNothing);
    expect(prefs.getInt(kAppOpenCountKey), 2);
  });

  testWidgets('adding runs the add flow for the chosen widget', (tester) async {
    SharedPreferences.setMockInitialValues(
      _inOnboarding({kHasSeenNotificationPrompt: true}),
    );
    final added = <QuotelyWidgetKind>[];
    await pump(tester, _app(initial: Routes.widgetOnboarding, added: added));

    await tester.tap(find.text('From your saved'));
    await _settle(tester);
    expect(find.textContaining('a different one each day'), findsOneWidget);
    await tester.tap(find.text('Add widget'));
    await _settle(tester);

    expect(added, [QuotelyWidgetKind.saved]);
    expect(find.text('TODAY'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kQuoteWidgetIntroShownKey), isTrue);
  });

  testWidgets('skipped where the widgets do not exist', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    SharedPreferences.setMockInitialValues(_inOnboarding());
    await pump(tester, _app(initial: Routes.notificationsOnboarding));
    expect(find.text('Step 3 of 3'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await _settle(tester);
    expect(find.text('TODAY'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  test('not offered once the intro has been shown', () async {
    SharedPreferences.setMockInitialValues({kQuoteWidgetIntroShownKey: true});
    final prefs = await SharedPreferences.getInstance();
    expect(WidgetOnboardingScreen.shouldShow(prefs), isFalse);
  });
}
