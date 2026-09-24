import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/dtos/media_title_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/dtos/scene_quote_dto.dart';
import 'package:quotely_flutter_app/navigation/bottom-navigation/bottom_navigation_layout.dart';
import 'package:quotely_flutter_app/navigation/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// Wraps [child] in the real Thread theme, like QuotelyApp does.
Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    ProviderScope(
      child: MaterialApp(
        theme: buildQuotelyTheme(brightness, const AppearanceSettings()),
        home: Scaffold(body: child),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('tokens', () {
    test('button text on every accent meets 4.5:1 in both themes', () {
      for (final b in Brightness.values) {
        for (final a in QAccent.values) {
          final t = QuotelyTokens.of(b, a);
          expect(
            _contrast(t.onAcc, t.acc),
            greaterThanOrEqualTo(4.5),
            reason: '$a in $b',
          );
          expect(_contrast(t.accInk, t.accSoft), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('mute text on bg passes 4.5:1', () {
      for (final b in Brightness.values) {
        final t = QuotelyTokens.of(b, QAccent.violet);
        expect(_contrast(t.mute, t.bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('legacy flex schemes map onto the five accents', () {
      expect(
        AppearanceSettings.accentForLegacyScheme('bahamaBlue'),
        QAccent.violet,
      );
      expect(
        AppearanceSettings.accentForLegacyScheme('aquaBlue'),
        QAccent.teal,
      );
      expect(AppearanceSettings.accentForLegacyScheme('jungle'), QAccent.green);
      expect(AppearanceSettings.accentForLegacyScheme('sakura'), QAccent.rose);
      expect(
        AppearanceSettings.accentForLegacyScheme('redWine'),
        QAccent.coral,
      );
    });

    test('old prefs migrate once and are removed', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode_key': 'dark',
        'is_flex_scheme_key': 'jungle',
        'font_family_key': 'Fira Code',
        'is-grid-view': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final s = await AppearanceSettings.load(prefs);
      expect(s.themeMode, ThemeMode.dark);
      expect(s.accent, QAccent.green);
      expect(s.readingFont, ReadingFont.mono);
      expect(s.layout, ThreadLayout.cards);
      expect(prefs.getString('is_flex_scheme_key'), isNull);
    });
  });

  test('old notification routes still resolve', () {
    expect(kLegacyRedirects['/settings'], Routes.you);
    expect(kLegacyRedirects['/favorites'], Routes.saved);
    expect(
      kLegacyRedirects['/quote-of-the-day'],
      '/past-messages?type=quote-of-the-day&latest=1',
    );
    expect(
      kLegacyRedirects['/fact-of-the-list'],
      '/past-messages?type=fact-of-the-day',
    );
  });

  testWidgets('bottom nav shows the five tabs and reports taps', (
    tester,
  ) async {
    var tapped = -1;
    await tester.pumpWidget(
      _host(
        Align(
          alignment: Alignment.bottomCenter,
          child: ThreadBottomNav(currentIndex: 0, onTap: (i) => tapped = i),
        ),
      ),
    );
    for (final label in ['Today', 'Scenes', 'Saved', 'People', 'Facts']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('People'));
    expect(tapped, 3);
  });

  for (final brightness in Brightness.values) {
    testWidgets('quote and scene bubbles render in ${brightness.name}', (
      tester,
    ) async {
      final d = DateTime.utc(2026);
      final quote = QuoteDto(
        id: 'q',
        author: 'Nelson Mandela',
        content: 'It always seems impossible until it’s done.',
        tags: const [],
        authorSlug: 'nelson-mandela',
        length: 44,
        dateAdded: d,
        dateModified: d,
      );
      final scene = SceneQuoteDto(
        id: 's',
        content: 'Hope is a good thing, maybe the best of things.',
        titleId: 't',
        titleName: 'The Shawshank Redemption',
        titleType: MediaType.movie,
        titleYear: 1994,
        characterId: 'c',
        characterName: 'Andy Dufresne',
        tags: const [],
        dateAdded: d,
        dateModified: d,
      );
      await tester.pumpWidget(
        _host(
          ListView(
            children: [
              MessageBubble(
                message: ThreadMessage.fromQuote(quote),
                variant: BubbleVariant.hero,
                showReactions: true,
                trackView: false,
              ),
              MessageBubble(
                message: ThreadMessage.fromScene(scene),
                trackView: false,
              ),
            ],
          ),
          brightness: brightness,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Nelson Mandela'), findsOneWidget);
      expect(find.text('The Shawshank Redemption'), findsOneWidget);
      expect(find.text('Movie · 1994'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
