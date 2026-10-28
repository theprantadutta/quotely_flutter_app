import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/dtos/ai_fact_dto.dart';
import 'package:quotely_flutter_app/dtos/media_title_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/dtos/scene_quote_dto.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A 1x1 PNG, standing in for a downloaded poster.
final _poster = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

const _short = 'Be kind.';
final _long = List.filled(
  14,
  'The only way to do great work is to love what you do, and to keep looking',
).join(' ');

ThreadMessage _quote(String text) => ThreadMessage.fromQuote(
  QuoteDto(
    id: 'q1',
    author: 'A Rather Long Author Name That Keeps Going And Going',
    content: text,
    tags: const ['wisdom'],
    authorSlug: 'author',
    length: text.length,
    dateAdded: DateTime.utc(2026),
    dateModified: DateTime.utc(2026),
  ),
);

ThreadMessage _scene(String text) => ThreadMessage.fromScene(
  SceneQuoteDto(
    id: 's1',
    content: text,
    titleId: 't1',
    titleName: 'The Shawshank Redemption: An Extended Title For Testing',
    titleType: MediaType.movie,
    titleYear: 1994,
    posterUrl: 'https://example.com/poster.jpg',
    characterId: 'c1',
    characterName: 'Andy Dufresne',
    tags: const [],
    dateAdded: DateTime.utc(2026),
    dateModified: DateTime.utc(2026),
  ),
);

ThreadMessage _fact(String text) => ThreadMessage.fromFact(
  AiFactDto(
    id: 1,
    content: text,
    aiFactCategory: 'science',
    provider: 'test',
    dateAdded: DateTime.utc(2026),
    dateModified: DateTime.utc(2026),
  ),
);

Widget _host(Widget child, Brightness brightness) => ProviderScope(
  child: MaterialApp(
    theme: buildQuotelyTheme(brightness, const AppearanceSettings()),
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final kinds = <String, ThreadMessage Function(String)>{
    'quote': _quote,
    'scene': _scene,
    'fact': _fact,
  };

  for (final MapEntry(key: kind, value: make) in kinds.entries) {
    for (final (label, text) in [('short', _short), ('long', _long)]) {
      for (final poster in [false, true]) {
        for (final b in Brightness.values) {
          final name =
              '$kind, $label text, ${poster ? 'poster' : 'no poster'}, '
              '${b.name}';
          testWidgets('share card builds without overflow: $name', (
            tester,
          ) async {
            final m = make(text);
            await tester.pumpWidget(
              _host(
                ShareCard(
                  message: m,
                  eyebrow: shareEyebrowFor(m),
                  poster: poster ? _poster : null,
                ),
                b,
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(tester.getSize(find.byType(ShareCard)), ShareCard.size);
            expect(find.text('Quotely'), findsWidgets);
          });
        }
      }
    }
  }

  for (final style in BackdropStyle.values) {
    testWidgets('share card follows the ${style.name} background', (
      tester,
    ) async {
      final m = _quote(_short);
      await tester.pumpWidget(
        _host(
          ShareCard(
            message: m,
            eyebrow: shareEyebrowFor(m),
            backdrop: style,
            poster: _poster,
          ),
          Brightness.light,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final washed = find.descendant(
        of: find.byType(ShareCard),
        matching: find.byType(ImageFiltered),
      );
      final glow = find.descendant(
        of: find.byType(ShareCard),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration).gradient is RadialGradient,
        ),
      );
      expect(
        washed,
        style == BackdropStyle.poster ? findsOneWidget : findsNothing,
      );
      expect(glow, style == BackdropStyle.glow ? findsWidgets : findsNothing);
    });
  }

  testWidgets('poster style without a poster falls back to the glow', (
    tester,
  ) async {
    final m = _fact(_short);
    await tester.pumpWidget(
      _host(ShareCard(message: m, eyebrow: 'Fact'), Brightness.dark),
    );
    expect(find.byType(ImageFiltered), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).gradient is RadialGradient,
      ),
      findsWidgets,
    );
  });

  testWidgets('Share as image shows a spinner and ignores taps until ready', (
    tester,
  ) async {
    var calls = 0;
    late bool Function() ready;
    final rendering = Completer<void>();
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showQSheet(
              context,
              builder: (_) => QSheetFrame(
                child: ShareImageAction(
                  onShare: (onRendered) {
                    calls++;
                    ready = onRendered;
                    return rendering.future;
                  },
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        Brightness.light,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share as image'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Share as image'), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    // The card is ready: the sheet closes before the system sheet opens.
    expect(ready(), isTrue);
    rendering.complete();
    await tester.pumpAndSettle();
    expect(find.text('Share as image'), findsNothing);
  });

  test('eyebrows name the kind', () {
    expect(shareEyebrowFor(_quote(_short)), 'Quote');
    expect(
      shareEyebrowFor(_quote(_short), hint: 'Quote of the day'),
      'Quote of the day',
    );
    expect(
      shareEyebrowFor(_scene(_short), hint: 'Scene of the day'),
      startsWith('Scene · The Shawshank'),
    );
    expect(shareEyebrowFor(_fact(_short)), 'Fact');
  });

  testWidgets('renders a 1080x1350 PNG offscreen', (tester) async {
    final m = _fact(_short);
    late BuildContext ctx;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sceneOfTheDayProvider.overrideWith((ref) async => null)],
        child: MaterialApp(
          theme: buildQuotelyTheme(
            Brightness.light,
            const AppearanceSettings(),
          ),
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final bytes = await tester.runAsync(() async {
      final pending = renderShareCard(ctx, m);
      // The capture waits on frames; drive them while it runs.
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        tester.binding.scheduleFrame();
        await tester.pump();
      }
      return pending;
    });
    expect(bytes, isNotNull);
    final codec = await tester.runAsync(() => ui.instantiateImageCodec(bytes!));
    final frame = await tester.runAsync(() => codec!.getNextFrame());
    expect(frame!.image.width, 1080);
    expect(frame.image.height, 1350);
    expect(tester.takeException(), isNull);
  });

  testWidgets('share sheet offers image first, then text', (tester) async {
    final m = _quote(_short);
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => shareMessage(context, m),
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
}
