import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/riverpods/backdrop_poster_provider.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:quotely_flutter_app/screens/appearance_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app shell as QuotelyApp builds it (theme, dark theme and mode from
/// [appearanceProvider], overlay style read from the theme in `builder`),
/// with a feed-like page under the pushed Appearance screen.
Widget _app() => ProviderScope(
  overrides: [
    sceneOfTheDayProvider.overrideWith((ref) async => null),
    fallbackPosterProvider.overrideWith((ref) async => null),
  ],
  child: Consumer(
    builder: (context, ref, _) {
      final appearance = ref.watch(appearanceProvider);
      return MaterialApp(
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: quotelyOverlayStyle(context.q),
          child: child!,
        ),
        theme: buildQuotelyTheme(Brightness.light, appearance),
        darkTheme: buildQuotelyTheme(Brightness.dark, appearance),
        themeMode: appearance.themeMode,
        home: const _Feed(),
      );
    },
  ),
);

class _Feed extends StatelessWidget {
  const _Feed();

  @override
  Widget build(BuildContext context) {
    final d = DateTime.utc(2026);
    final quote = QuoteDto(
      id: 'q',
      author: 'Nelson Mandela',
      content: 'It always seems impossible until it’s done.',
      tags: const ['hope'],
      authorSlug: 'nelson-mandela',
      length: 44,
      dateAdded: d,
      dateModified: d,
    );
    return PageBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          children: [
            MessageBubble(
              message: ThreadMessage.fromQuote(quote),
              variant: BubbleVariant.hero,
              showReactions: true,
              trackView: false,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AppearanceScreen(),
                ),
              ),
              child: const Text('Open appearance'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Appearance.bootstrap = const AppearanceSettings();
  });

  testWidgets('switching theme and accent repeatedly never throws', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Open appearance'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    final modes = ['Dark', 'Light', 'System', 'Dark', 'System', 'Light'];
    final accents = [for (final a in QAccent.values) '${a.label} accent'];
    for (var round = 0; round < 3; round++) {
      for (var i = 0; i < modes.length; i++) {
        await tester.tap(find.bySemanticsLabel(modes[i]));
        // Change again mid-animation, while the theme is still lerping.
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(
          find.bySemanticsLabel(accents[(i + round) % accents.length]),
        );
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.takeException(), isNull);
      }
      // The OS flipping light/dark while in System mode.
      tester.platformDispatcher.platformBrightnessTestValue = round.isEven
          ? Brightness.dark
          : Brightness.light;
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();

    await tester.pumpAndSettle();
    // Back to the feed underneath (the header's back button needs go_router).
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Nelson Mandela'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing the background keeps the screen state', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Open appearance'));
    await tester.pumpAndSettle();

    final list = find.byType(Scrollable).last;
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
    double offset() => tester.state<ScrollableState>(list).position.pixels;
    final before = offset();
    expect(before, greaterThan(0));

    for (final style in ['Plain', 'Glow', 'Poster', 'Plain']) {
      await tester.tap(find.bySemanticsLabel(style));
      await tester.pumpAndSettle();
      expect(offset(), before, reason: 'after $style');
    }
    expect(tester.takeException(), isNull);
  });
}
