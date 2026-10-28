import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/supporter_thanks.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget home) => ProviderScope(
  overrides: [sceneOfTheDayProvider.overrideWith((ref) async => null)],
  child: MaterialApp(
    theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
    home: home,
  ),
);

/// The seal breathes forever, so step frames instead of settling.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the eyebrow carries the supporter date when known', () {
    expect(
      supporterEyebrow(DateTime(2026, 10, 28)),
      'Quotely supporter · since 28 Oct 2026',
    );
    expect(supporterEyebrow(null), 'Quotely supporter');
  });

  testWidgets('the supporter letter thanks them and asks for nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Scaffold(
          body: ListView(
            children: [SupporterLetter(since: DateTime(2026, 10, 28))],
          ),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('Thank you. Truly.'), findsOneWidget);
    expect(find.text('QUOTELY SUPPORTER · SINCE 28 OCT 2026'), findsOneWidget);
    expect(find.text('Pranta'), findsOneWidget);
    expect(find.textContaining('\$'), findsNothing);
  });

  for (final restored in [false, true]) {
    testWidgets('the thank-you moment (restored: $restored) closes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showThankYouMoment(context, restored: restored),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await _settle(tester);

      expect(
        find.text(
          restored
              ? 'You are still a Quotely supporter.'
              : 'You just made Quotely possible.',
        ),
        findsOneWidget,
      );

      // A short test screen puts the button below the fold: it scrolls.
      await tester.ensureVisible(find.text('Back to Quotely'));
      await tester.tap(find.text('Back to Quotely'));
      await _settle(tester);
      expect(find.text('Back to Quotely'), findsNothing);
    });
  }
}
