import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quotely_flutter_app/components/thread/facts_score.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:quotely_flutter_app/services/facts_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _poster = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

const _eight = [true, true, false, true, true, true, false, true, true, true];

Widget _host(Widget child, Brightness brightness) => ProviderScope(
  overrides: [sceneOfTheDayProvider.overrideWith((ref) async => null)],
  child: MaterialApp(
    theme: buildQuotelyTheme(brightness, const AppearanceSettings()),
    home: Scaffold(body: Center(child: child)),
  ),
);

Iterable<Container> _dots(WidgetTester tester) => tester.widgetList<Container>(
  find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('facts-dot-'),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('share card', () {
    for (final b in Brightness.values) {
      for (final style in BackdropStyle.values) {
        for (final (label, results, streak) in [
          ('8/10, 6-day streak', _eight, 6),
          ('0/10, no streak', List.filled(10, false), 0),
          ('10/10, long streak', List.filled(10, true), 365),
        ]) {
          testWidgets('builds: $label, ${style.name}, ${b.name}', (
            tester,
          ) async {
            await tester.pumpWidget(
              _host(
                FactsScoreShareCard(
                  results: results,
                  streak: streak,
                  backdrop: style,
                  poster: _poster,
                ),
                b,
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(
              tester.getSize(find.byType(FactsScoreShareCard)),
              ShareCard.size,
            );
            expect(find.text('QUOTELY · TRUE OR FALSE'), findsOneWidget);
            expect(find.text('Quotely'), findsOneWidget);
            expect(_dots(tester), hasLength(kFactsPerDay));
          });
        }
      }
    }

    testWidgets('shows the score, dots and streak, never the answers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FactsScoreShareCard(results: _eight, streak: 6),
          Brightness.light,
        ),
      );
      expect(find.text('8/10'), findsOneWidget);
      expect(find.text('6-day streak'), findsOneWidget);
      expect(find.bySemanticsLabel('8 right, 2 wrong'), findsOneWidget);
      // Only the eyebrow, score, streak, wordmark and tagline: no facts,
      // no "true"/"false" verdicts per question.
      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(FactsScoreShareCard),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(texts, hasLength(5));
    });

    testWidgets('right dots take the accent, wrong ones a muted tone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FactsScoreShareCard(results: _eight, streak: 6),
          Brightness.light,
        ),
      );
      final ctx = tester.element(find.byType(FactsScoreShareCard));
      final acc = ctx.q.acc;
      final colors = _dots(
        tester,
      ).map((c) => (c.decoration! as BoxDecoration).color).toList();
      for (var i = 0; i < kFactsPerDay; i++) {
        if (_eight[i]) {
          expect(colors[i], acc);
        } else {
          expect(colors[i], isNot(acc));
        }
      }
    });

    testWidgets('renders a 1080x1350 PNG offscreen', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
          Brightness.light,
        ),
      );
      final bytes = await tester.runAsync(() async {
        final pending = renderFactsScoreCard(ctx, results: _eight, streak: 6);
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          tester.binding.scheduleFrame();
          await tester.pump();
        }
        return pending;
      });
      expect(bytes, isNotNull);
      final codec = await tester.runAsync(
        () => ui.instantiateImageCodec(bytes!),
      );
      final frame = await tester.runAsync(() => codec!.getNextFrame());
      expect(frame!.image.width, 1080);
      expect(frame.image.height, 1350);
    });
  });

  group('result card', () {
    final round = FactsRound(day: '2026-11-17', results: _eight);

    for (final size in [const Size(320, 480), const Size(412, 860)]) {
      testWidgets('fits a ${size.width.toInt()}x${size.height.toInt()} '
          'screen', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            SizedBox.expand(
              child: FactsResultCard(
                round: round,
                streak: 6,
                best: 9,
                onShare: () {},
                onBrowse: () {},
              ),
            ),
            Brightness.dark,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('8 out of 10 today'), findsOneWidget);
        expect(find.text('Sharp!'), findsOneWidget);
        expect(find.text('6-day streak · Best 9'), findsOneWidget);
        expect(find.text('Share score'), findsOneWidget);
        expect(find.text('Browse facts'), findsOneWidget);
      });
    }

    testWidgets('actions call back', (tester) async {
      var shared = 0, browsed = 0;
      await tester.pumpWidget(
        _host(
          SizedBox.expand(
            child: FactsResultCard(
              round: round,
              streak: 1,
              best: 1,
              onShare: () => shared++,
              onBrowse: () => browsed++,
            ),
          ),
          Brightness.light,
        ),
      );
      expect(find.text('1-day streak'), findsOneWidget);
      await tester.tap(find.text('Share score'));
      await tester.tap(find.text('Browse facts'));
      expect(shared, 1);
      expect(browsed, 1);
    });

    testWidgets('Share my score offers image first, then text', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  shareFactsScore(context, round: round, streak: 6),
              child: const Text('open'),
            ),
          ),
          Brightness.light,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final image = tester.getTopLeft(find.text('Share as image'));
      final text = tester.getTopLeft(find.text('Share as text'));
      expect(image.dy, lessThan(text.dy));
    });
  });
}
