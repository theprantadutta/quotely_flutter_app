import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quotely_flutter_app/components/coming_soon.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/dtos/coming_soon_dto.dart';
import 'package:quotely_flutter_app/dtos/media_title_dto.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:quotely_flutter_app/services/app_analytics.dart';
import 'package:quotely_flutter_app/services/coming_soon_service.dart';
import 'package:quotely_flutter_app/util/countdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _body = '''
[{ "id": "cs-1", "name": "Avengers: Doomsday", "type": "movie",
   "releaseDate": "2026-12-16", "daysUntil": 29, "reason": "upcoming",
   "posterUrl": "https://example.com/doomsday.jpg",
   "overview": "The Avengers face Doctor Doom.",
   "titles": [{ "id": "t-1", "slug": "avengers-endgame",
     "name": "Avengers: Endgame", "type": "movie",
     "posterUrl": "https://example.com/endgame.jpg",
     "yearStart": 2019, "lineCount": 9 }] },
 { "id": "cs-2", "name": "Arcane", "type": "tv", "releaseDate": null,
   "daysUntil": null, "reason": "trending", "posterUrl": null,
   "overview": "", "titles": [{ "id": "t-2", "slug": "arcane",
     "name": "Arcane", "type": "tv", "yearStart": 2021, "lineCount": 1 }] }]
''';

/// Tuesday 17 November 2026, mid-morning.
final _now = DateTime(2026, 11, 17, 10);

Response _ok(String body) => Response(
  requestOptions: RequestOptions(path: '/'),
  statusCode: 200,
  data: body,
);

Response _status(int code) => Response(
  requestOptions: RequestOptions(path: '/'),
  statusCode: code,
);

DateTime _daysFromToday(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

ComingSoonTitleDto _title(String id, String name) => ComingSoonTitleDto(
  id: id,
  slug: id,
  name: name,
  type: MediaType.movie,
  yearStart: 2019,
  lineCount: 3,
);

final _single = ComingSoonDto(
  id: 'single',
  name: 'Dune: Part Three',
  type: MediaType.movie,
  releaseDate: _daysFromToday(40),
  overview: 'Paul, years later.',
  titles: [_title('dune-2', 'Dune: Part Two')],
);

final _several = ComingSoonDto(
  id: 'several',
  name: 'Avengers: Doomsday',
  type: MediaType.movie,
  releaseDate: _daysFromToday(0),
  overview: 'The Avengers face Doctor Doom.',
  titles: [
    _title('endgame', 'Avengers: Endgame'),
    _title('infinity-war', 'Avengers: Infinity War'),
  ],
);

Widget _host(List<ComingSoonDto> items, {OpenTitle? openTitle}) =>
    ProviderScope(
      overrides: [comingSoonProvider.overrideWith((ref) async => items)],
      child: MaterialApp(
        theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
        home: Scaffold(
          body: ListView(
            children: [
              ComingSoonStrip(openTitle: openTitle),
              const Text('Trending titles'),
            ],
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ComingSoonDto', () {
    test('parses the response', () {
      final items = ComingSoonDto.listFromJson(json.decode(_body));
      expect(items, hasLength(2));
      final first = items.first;
      expect(first.name, 'Avengers: Doomsday');
      expect(first.type, MediaType.movie);
      expect(first.releaseDate, DateTime(2026, 12, 16));
      expect(first.daysUntil, 29);
      expect(first.reason, ComingSoonReason.upcoming);
      expect(first.titles.single.slug, 'avengers-endgame');
      expect(first.titles.single.lineCount, 9);
      expect(first.titles.single.meta, 'Movie · 2019 · 9 lines');
      expect(first.titles.single.route, 't-1');
    });

    test('a trending item has no date', () {
      final trending = ComingSoonDto.listFromJson(json.decode(_body)).last;
      expect(trending.reason, ComingSoonReason.trending);
      expect(trending.releaseDate, isNull);
      expect(trending.daysUntil, isNull);
      expect(trending.type, MediaType.tv);
      expect(trending.titles.single.meta, 'TV · 2021 · 1 line');
    });

    test('anything but a list reads as empty', () {
      expect(ComingSoonDto.listFromJson({'error': 'nope'}), isEmpty);
      expect(ComingSoonDto.listFromJson(null), isEmpty);
    });
  });

  group('countdownLabel', () {
    String label(int days) =>
        countdownLabel(DateTime(2026, 11, 17).add(Duration(days: days)), _now);

    test('reads the days ahead', () {
      expect(label(0), 'Out today');
      expect(label(1), 'Tomorrow');
      expect(label(2), 'Out Thursday');
      expect(label(3), 'Out Friday');
      expect(label(6), 'Out Monday');
      expect(label(7), 'In 7 days');
      expect(label(29), 'In 29 days');
    });

    test('no date, or one already past, is trending', () {
      expect(countdownLabel(null, _now), 'Trending');
      expect(label(-1), 'Trending');
    });

    test('counts calendar days, not hours', () {
      final lateNight = DateTime(2026, 11, 17, 23, 59);
      expect(countdownLabel(DateTime(2026, 11, 18), lateNight), 'Tomorrow');
      final earlyMorning = DateTime(2026, 11, 17, 0, 1);
      expect(countdownLabel(DateTime(2026, 11, 17), earlyMorning), 'Out today');
    });

    test('crosses the DST change cleanly', () {
      // Europe and the US leave summer time on these dates.
      expect(
        daysUntilRelease(DateTime(2026, 11, 2), DateTime(2026, 10, 24, 12)),
        9,
      );
    });
  });

  group('ComingSoonService', () {
    tearDown(() => ComingSoonService.fetch = (_) async => _status(404));

    test('a good response is returned and saved', () async {
      ComingSoonService.fetch = (_) async => _ok(_body);
      final items = await ComingSoonService.getComingSoon(now: _now);
      expect(items.map((i) => i.id), ['cs-1', 'cs-2']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ComingSoonService.cacheKey), _body);
    });

    test('offline, the saved copy is shown', () async {
      SharedPreferences.setMockInitialValues({
        ComingSoonService.cacheKey: _body,
      });
      ComingSoonService.fetch = (_) async => throw DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      final items = await ComingSoonService.getComingSoon(now: _now);
      expect(items.map((i) => i.id), ['cs-1', 'cs-2']);
    });

    test('offline with nothing saved is empty, not an error', () async {
      ComingSoonService.fetch = (_) async => throw Exception('offline');
      expect(await ComingSoonService.getComingSoon(now: _now), isEmpty);
    });

    test('an old backend (404) is empty, silently', () async {
      ComingSoonService.fetch = (_) async => _status(404);
      expect(await ComingSoonService.getComingSoon(now: _now), isEmpty);

      ComingSoonService.fetch = (_) async => throw DioException(
        requestOptions: RequestOptions(path: '/'),
        response: _status(404),
        type: DioExceptionType.badResponse,
      );
      expect(await ComingSoonService.getComingSoon(now: _now), isEmpty);
    });

    test('a saved release already out is dropped', () {
      final items = ComingSoonDto.listFromJson(json.decode(_body));
      final afterRelease = DateTime(2026, 12, 17);
      expect(ComingSoonService.visible(items, afterRelease).map((i) => i.id), [
        'cs-2',
      ]);
      expect(
        ComingSoonService.visible(items, DateTime(2026, 12, 16)),
        hasLength(2),
      );
    });
  });

  group('ComingSoonStrip', () {
    testWidgets('is hidden when the list is empty', (tester) async {
      await tester.pumpWidget(_host(const []));
      await tester.pumpAndSettle();
      expect(find.text('Coming soon'), findsNothing);
      expect(find.byType(ComingSoonCard), findsNothing);
      expect(find.text('Trending titles'), findsOneWidget);
    });

    testWidgets('shows a card per item with its countdown', (tester) async {
      await tester.pumpWidget(_host([_single, _several]));
      await tester.pumpAndSettle();
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.byType(ComingSoonCard), findsNWidgets(2));
      expect(find.text('IN 40 DAYS'), findsOneWidget);
      expect(find.text('OUT TODAY'), findsOneWidget);
    });

    testWidgets('one linked title opens directly', (tester) async {
      final opened = <String>[];
      final events = <String>[];
      final sub = AppEvents.stream.listen((e) => events.add(e.name));
      addTearDown(sub.cancel);

      await tester.pumpWidget(_host([_single], openTitle: opened.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ComingSoonCard));
      await tester.pumpAndSettle();

      expect(opened, ['dune-2']);
      expect(find.text('Before Dune: Part Three'), findsNothing);
      expect(events, ['coming_soon_opened', 'coming_soon_title_opened']);
    });

    testWidgets('several linked titles open a sheet to pick from', (
      tester,
    ) async {
      final opened = <String>[];
      final events = <String>[];
      final sub = AppEvents.stream.listen((e) => events.add(e.name));
      addTearDown(sub.cancel);

      await tester.pumpWidget(_host([_several], openTitle: opened.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ComingSoonCard));
      await tester.pumpAndSettle();

      expect(find.text('Before Avengers: Doomsday'), findsOneWidget);
      expect(find.text('The Avengers face Doctor Doom.'), findsOneWidget);
      expect(find.text('Avengers: Endgame'), findsOneWidget);
      expect(find.text('Avengers: Infinity War'), findsOneWidget);
      expect(opened, isEmpty);
      expect(events, ['coming_soon_opened']);

      await tester.tap(find.text('Avengers: Infinity War'));
      await tester.pumpAndSettle();
      expect(opened, ['infinity-war']);
      expect(find.text('Before Avengers: Doomsday'), findsNothing);
      expect(events, ['coming_soon_opened', 'coming_soon_title_opened']);
    });
  });
}
