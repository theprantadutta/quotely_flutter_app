import 'package:drift/native.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/components/settings_button.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/database/database.dart';
import 'package:quotely_flutter_app/dtos/ai_fact_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/dtos/scene_quote_dto.dart';
import 'package:quotely_flutter_app/screens/tab_screens/saved_screen.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';
import 'package:quotely_flutter_app/services/drift_collection_service.dart';
import 'package:quotely_flutter_app/services/drift_fact_service.dart';
import 'package:quotely_flutter_app/services/drift_quote_service.dart';
import 'package:quotely_flutter_app/services/drift_scene_service.dart';
import 'package:quotely_flutter_app/services/retractions.dart';
import 'package:quotely_flutter_app/services/saved_feed_service.dart';
import 'package:quotely_flutter_app/services/saved_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _old = DateTime(2025, 1, 1);

Quote _quote(String id, {DateTime? savedAt, DateTime? modified, String? by}) =>
    Quote(
      id: id,
      author: by ?? 'Author $id',
      content: 'Quote $id',
      tags: '',
      authorSlug: 'author-$id',
      length: 7,
      isFavorite: true,
      dateAdded: _old,
      dateModified: modified ?? _old,
      savedAt: savedAt,
    );

Fact _fact(int id, {DateTime? savedAt, DateTime? modified}) => Fact(
  id: id,
  content: 'Fact $id',
  aiFactCategory: 'Space',
  provider: 'x',
  isFavorite: true,
  dateAdded: _old,
  dateModified: modified ?? _old,
  savedAt: savedAt,
);

SceneQuote _scene(String id, {DateTime? savedAt, bool spoiler = false}) =>
    SceneQuote(
      id: id,
      content: 'Scene $id',
      titleId: 't1',
      titleSlug: 'show',
      titleName: 'The Show',
      titleType: 'series',
      characterId: 'c1',
      characterName: 'Cee',
      isSpoiler: spoiler,
      tags: '',
      likes: 0,
      isFavorite: true,
      dateAdded: _old,
      dateModified: _old,
      savedAt: savedAt,
    );

List<String> _keys(Iterable<SavedEntry> entries) => [
  for (final e in entries) e.key,
];

/// Records analytics events instead of sending them.
class _FakeAnalytics implements FirebaseAnalytics {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
    List<AnalyticsEventItem>? items,
    AnalyticsCallOptions? callOptions,
  }) async => events.add((name, parameters));

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  final now = DateTime(2026, 11, 18, 10); // a Wednesday
  DateTime daysAgo(int d, [int hour = 9]) =>
      DateTime(now.year, now.month, now.day - d, hour);

  group('feed order', () {
    test('newest saved first, across kinds', () {
      final feed = SavedFeedService.sorted([
        SavedEntry.fromQuote(_quote('a', savedAt: daysAgo(3))),
        SavedEntry.fromFact(_fact(1, savedAt: daysAgo(0))),
        SavedEntry.fromScene(_scene('s', savedAt: daysAgo(1))),
      ]);
      expect(_keys(feed), ['fact:1', 'scene:s', 'quote:a']);
    });

    test('undated (saved before v4) go last, most recently changed first', () {
      final feed = SavedFeedService.sorted([
        SavedEntry.fromQuote(_quote('old', modified: DateTime(2025, 3))),
        SavedEntry.fromQuote(_quote('older', modified: DateTime(2024, 3))),
        SavedEntry.fromQuote(_quote('dated', savedAt: daysAgo(40))),
      ]);
      expect(_keys(feed), ['quote:dated', 'quote:old', 'quote:older']);
    });

    test('ties are stable whatever order the rows came in', () {
      final at = daysAgo(2);
      final rows = [
        SavedEntry.fromQuote(_quote('b', savedAt: at)),
        SavedEntry.fromQuote(_quote('a', savedAt: at)),
      ];
      expect(
        _keys(SavedFeedService.sorted(rows)),
        _keys(SavedFeedService.sorted(rows.reversed)),
      );
    });
  });

  group('filters', () {
    final feed = SavedFeed(
      entries: SavedFeedService.sorted([
        SavedEntry.fromQuote(
          _quote('q', savedAt: daysAgo(0), by: 'Maya Angelou'),
        ),
        SavedEntry.fromScene(_scene('s', savedAt: daysAgo(1))),
        SavedEntry.fromFact(_fact(1, savedAt: daysAgo(2))),
      ]),
      collections: const [
        CollectionSummary(1, 'Morning', 2),
        CollectionSummary(2, 'Work', 0),
      ],
      memberships: const {
        'quote:q': {1},
        'fact:1': {1, 2},
        'quote:unsaved': {2},
      },
    );

    test('All keeps everything in order', () {
      expect(_keys(SavedFeedService.apply(feed, SavedFilter.all)), [
        'quote:q',
        'scene:s',
        'fact:1',
      ]);
    });

    test('a kind chip keeps only that kind', () {
      for (final (kind, key) in [
        (MessageKind.quote, 'quote:q'),
        (MessageKind.scene, 'scene:s'),
        (MessageKind.fact, 'fact:1'),
      ]) {
        expect(_keys(SavedFeedService.apply(feed, SavedFilter.kind(kind))), [
          key,
        ]);
      }
    });

    test('a collection chip keeps only its saved items', () {
      expect(
        _keys(SavedFeedService.apply(feed, const SavedFilter.collection(1))),
        ['quote:q', 'fact:1'],
      );
      expect(
        _keys(SavedFeedService.apply(feed, const SavedFilter.collection(2))),
        ['fact:1'],
      );
    });

    test('search matches the line, who said it and the source', () {
      List<String> search(String q) =>
          _keys(SavedFeedService.apply(feed, SavedFilter.all, query: q));
      expect(search('angelou'), ['quote:q']);
      expect(search('  SCENE s '), ['scene:s']);
      expect(search('the show'), ['scene:s']);
      expect(search('space'), ['fact:1']);
      expect(search('nothing like it'), isEmpty);
    });

    test('search narrows within the chip', () {
      expect(
        SavedFeedService.apply(
          feed,
          const SavedFilter.kind(MessageKind.fact),
          query: 'angelou',
        ),
        isEmpty,
      );
    });

    test('tags are named in chip order', () {
      expect(feed.tagsOf(feed.entries.last), ['Morning', 'Work']);
      expect(feed.tagsOf(feed.entries[1]), isEmpty);
    });

    test('filters compare by value', () {
      expect(
        const SavedFilter.kind(MessageKind.quote),
        SavedFilter.kind(MessageKind.quote),
      );
      expect(
        const SavedFilter.collection(1),
        isNot(const SavedFilter.collection(2)),
      );
      expect(SavedFilter.all.isAll, isTrue);
    });
  });

  group('date headers', () {
    List<String> labels(List<DateTime?> dates) {
      final entries = SavedFeedService.sorted([
        for (var i = 0; i < dates.length; i++)
          SavedEntry.fromQuote(_quote('$i', savedAt: dates[i])),
      ]);
      return [for (final g in SavedFeedService.group(entries, now)) g.label];
    }

    test('days for the last week, then weeks, then months', () {
      expect(
        labels([
          daysAgo(0, 8),
          daysAgo(0, 7),
          daysAgo(1),
          daysAgo(6),
          daysAgo(8), // Tuesday the 10th
          daysAgo(9), // Monday the 9th
          DateTime(2026, 3, 4),
          DateTime(2025, 12, 24),
          null,
        ]),
        [
          'Saved today',
          'Saved yesterday',
          'Saved Thursday',
          'Saved the week of Nov 9',
          'Saved in March',
          'Saved in December 2025',
          'Saved earlier',
        ],
      );
    });

    test('one header per run, items stay in order inside it', () {
      final entries = SavedFeedService.sorted([
        SavedEntry.fromQuote(_quote('a', savedAt: daysAgo(0, 8))),
        SavedEntry.fromFact(_fact(1, savedAt: daysAgo(0, 9))),
      ]);
      final groups = SavedFeedService.group(entries, now);
      expect(groups, hasLength(1));
      expect(_keys(groups.single.entries), ['fact:1', 'quote:a']);
    });
  });

  group('revisit', () {
    final pool = [
      SavedEntry.fromQuote(_quote('recent', savedAt: daysAgo(2))),
      SavedEntry.fromQuote(_quote('a', savedAt: daysAgo(21))),
      SavedEntry.fromFact(_fact(1, savedAt: daysAgo(30))),
      SavedEntry.fromScene(
        _scene('spoiler', savedAt: daysAgo(40), spoiler: true),
      ),
      SavedEntry.fromQuote(_quote('undated')),
    ];

    test('only things saved a while ago, never spoilers', () {
      final picks = {
        // Within the week, so 'recent' stays recent.
        for (var d = 0; d < 5; d++)
          SavedFeedService.revisitFor(pool, now.add(Duration(days: d)))?.key,
      };
      expect(picks, {'quote:a', 'fact:1', 'quote:undated'});
    });

    test('stable through the day, whatever the row order', () {
      final morning = DateTime(2026, 11, 18, 0, 5);
      final night = DateTime(2026, 11, 18, 23, 55);
      expect(
        SavedFeedService.revisitFor(pool, morning)!.key,
        SavedFeedService.revisitFor(pool.reversed, night)!.key,
      );
    });

    test('changes from one day to the next', () {
      final today = SavedFeedService.revisitFor(pool, now)!.key;
      final tomorrow = SavedFeedService.revisitFor(
        pool,
        now.add(const Duration(days: 1)),
      )!.key;
      expect(tomorrow, isNot(today));
    });

    test('is the saved widget’s pick over the eligible pool', () {
      final eligible = [pool[1], pool[2], pool[4]];
      for (var d = 0; d < 6; d++) {
        final day = now.add(Duration(days: d));
        final widgetPick = SavedWidgetService.pickFor([
          for (final e in eligible)
            SavedWidgetQuote(
              id: e.key,
              text: e.message.text,
              author: e.message.sender,
              added: e.savedAt ?? e.fallback,
            ),
        ], day);
        expect(SavedFeedService.revisitFor(pool, day)!.key, widgetPick!.id);
      }
    });

    test('nothing when everything is recent', () {
      expect(SavedFeedService.revisitFor([pool.first], now), isNull);
      expect(SavedFeedService.revisitFor(const [], now), isNull);
    });

    test('says how long ago', () {
      String label(DateTime? at) => SavedFeedService.revisitLabel(
        SavedEntry.fromQuote(_quote('x', savedAt: at)),
        now,
      );
      expect(label(daysAgo(7)), 'From your saved, a week ago');
      expect(label(daysAgo(10)), 'From your saved, 10 days ago');
      expect(label(daysAgo(21)), 'From your saved, 3 weeks ago');
      expect(label(daysAgo(95)), 'From your saved, 3 months ago');
      expect(label(daysAgo(400)), 'From your saved, a year ago');
      expect(label(null), 'From your saved, a while ago');
    });
  });

  group('database', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton<AppDatabase>(db);
    });

    tearDown(() async {
      await getIt.reset(dispose: false);
      await db.close();
    });

    test('saving records when; unsaving clears it', () async {
      final quote = QuoteDto.fromQuote(_quote('q'));
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      await DriftQuoteService.changeQuoteUpdateStatus(quote, true);
      var row = await db.select(db.quotes).getSingle();
      expect(row.savedAt!.isAfter(before), isTrue);

      // A library sync of the same quote keeps the saved time.
      await DriftQuoteService.saveNewQuotesToDatabase([quote]);
      expect((await db.select(db.quotes).getSingle()).savedAt, row.savedAt);

      await DriftQuoteService.changeQuoteUpdateStatus(quote, false);
      row = await db.select(db.quotes).getSingle();
      expect(row.isFavorite, isFalse);
      expect(row.savedAt, isNull);
    });

    test('scenes and facts record it too', () async {
      await DriftSceneService.setFavorite(
        SceneQuoteDto.fromDrift(_scene('s')),
        true,
      );
      await DriftFactService.changeFactFavoriteStatus(
        AiFactDto.fromDrift(_fact(1)),
        true,
      );
      expect((await db.select(db.sceneQuotes).getSingle()).savedAt, isNotNull);
      expect((await db.select(db.facts).getSingle()).savedAt, isNotNull);

      await DriftSceneService.setFavorite(
        SceneQuoteDto.fromDrift(_scene('s')),
        false,
      );
      expect((await db.select(db.sceneQuotes).getSingle()).savedAt, isNull);
    });

    test('the feed mixes kinds, newest first, with tags', () async {
      await db.into(db.quotes).insert(_quote('q', savedAt: daysAgo(2)));
      await db.into(db.facts).insert(_fact(1, savedAt: daysAgo(1)));
      await db.into(db.sceneQuotes).insert(_scene('s', savedAt: daysAgo(3)));
      await db
          .into(db.quotes)
          .insert(_quote('unsaved').copyWith(isFavorite: false));
      final id = await DriftCollectionService.create('Morning');
      await DriftCollectionService.add(id, CollectionItemType.fact, '1');

      final feed = await SavedFeedService.watch().first;
      expect(_keys(feed.entries), ['fact:1', 'quote:q', 'scene:s']);
      expect(feed.tagsOf(feed.entries.first), ['Morning']);
      expect(feed.count(MessageKind.quote), 1);
    });

    test(
      'collections count only saved items; unsaving keeps the tag',
      () async {
        final quote = QuoteDto.fromQuote(_quote('q'));
        await DriftQuoteService.changeQuoteUpdateStatus(quote, true);
        final id = await DriftCollectionService.create('Work');
        await DriftCollectionService.add(id, CollectionItemType.quote, 'q');
        expect(
          (await DriftCollectionService.watchCollections().first).single.count,
          1,
        );

        await DriftQuoteService.changeQuoteUpdateStatus(quote, false);
        expect(
          (await DriftCollectionService.watchCollections().first).single.count,
          0,
        );
        expect(
          await DriftCollectionService.collectionsContaining(
            CollectionItemType.quote,
            'q',
          ),
          {id},
        );

        // Saving it again brings it back into the collection.
        await DriftQuoteService.changeQuoteUpdateStatus(quote, true);
        expect(
          (await DriftCollectionService.watchCollections().first).single.count,
          1,
        );
      },
    );

    test('deleting a collection keeps its items saved', () async {
      await db.into(db.quotes).insert(_quote('q', savedAt: daysAgo(1)));
      final id = await DriftCollectionService.create('Gone');
      await DriftCollectionService.add(id, CollectionItemType.quote, 'q');
      await DriftCollectionService.delete(id);
      final feed = await SavedFeedService.watch().first;
      expect(_keys(feed.entries), ['quote:q']);
      expect(feed.collections, isEmpty);
      expect(feed.memberships, isEmpty);
    });
  });

  group('Saved screen', () {
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        kAcceptedLegalVersionKey: kCurrentLegalVersion,
        'scenes-seed-loaded-v1': true,
      });
      getIt.registerSingleton<FirebaseAnalytics>(_FakeAnalytics());
      db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton<AppDatabase>(db);
    });

    tearDown(() => getIt.reset(dispose: false));

    Widget app() => ProviderScope(
      child: MaterialApp.router(
        theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: SavedScreen()),
            ),
          ],
        ),
      ),
    );

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> teardown(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    }

    // Seed before pumping: writes from runAsync while the screen's queries
    // are open would wait on the fake clock forever.
    Future<void> seed(WidgetTester tester, {String? collection}) async {
      // Tall enough that the whole feed is laid out.
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        final today = DateTime.now();
        DateTime ago(int d) =>
            DateTime(today.year, today.month, today.day - d, 9);
        await db.into(db.quotes).insert(_quote('q', savedAt: today));
        await db.into(db.facts).insert(_fact(1, savedAt: ago(1)));
        await db.into(db.sceneQuotes).insert(_scene('s', savedAt: ago(21)));
        if (collection != null) {
          final id = await DriftCollectionService.create(collection);
          await DriftCollectionService.add(id, CollectionItemType.quote, 'q');
        }
      });
    }

    testWidgets('one feed under date headers, with a revisit on top', (
      tester,
    ) async {
      await seed(tester);
      await tester.pumpWidget(app());
      await settle(tester);

      expect(find.text('SAVED TODAY'), findsOneWidget);
      expect(find.text('SAVED YESTERDAY'), findsOneWidget);
      expect(find.text('Quote q'), findsOneWidget);
      expect(find.text('Fact 1'), findsOneWidget);
      // The only thing saved a while ago comes back at the top.
      expect(find.text('FROM YOUR SAVED, 3 WEEKS AGO'), findsOneWidget);
      expect(find.text('Scene s'), findsWidgets);

      // Gone: the List/Cards toggle, the kind tabs and the "+ New" box.
      expect(find.text('Cards'), findsNothing);
      expect(find.text('+ New'), findsNothing);
      expect(find.byType(SettingsButton), findsOneWidget);
      await teardown(tester);
    });

    testWidgets('saved items the checks hid stay, with an honest note', (
      tester,
    ) async {
      Retractions.resetForTest({
        'quote:q': const Retraction(
          reason: 'misattributed',
          probablyBy: 'Mark Twain',
          replacementId: 'r1',
        ),
        'fact:1': const Retraction(reason: 'not_accurate'),
      });
      addTearDown(Retractions.resetForTest);
      await seed(tester);
      await tester.pumpWidget(app());
      await settle(tester);

      // Still saved and shown; nothing a person saved is removed.
      expect(find.text('Quote q'), findsOneWidget);
      expect(find.text('Fact 1'), findsOneWidget);
      expect(
        find.text(
          'Our checks found this is probably by Mark Twain, not Author q. '
          'Tap for a verified one.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Our fact-check found this isn’t accurate.'),
        findsOneWidget,
      );
      await teardown(tester);
    });

    testWidgets('kind chips filter the feed', (tester) async {
      await seed(tester);
      await tester.pumpWidget(app());
      await settle(tester);

      await tester.tap(find.text('Facts'));
      await settle(tester);
      expect(find.text('Fact 1'), findsOneWidget);
      expect(find.text('Quote q'), findsNothing);
      expect(find.text('Scene s'), findsNothing);
      await teardown(tester);
    });

    testWidgets('a collection is a chip after the kinds, and a tag', (
      tester,
    ) async {
      await seed(tester, collection: 'Morning');
      await tester.pumpWidget(app());
      await settle(tester);
      // The chip, and the tag on the card.
      expect(find.text('Morning'), findsNWidgets(2));

      await tester.tap(find.text('Morning').first);
      await settle(tester);
      expect(find.text('1 saved in Morning'), findsOneWidget);
      expect(find.text('Quote q'), findsOneWidget);
      expect(find.text('Fact 1'), findsNothing);
      await teardown(tester);
    });

    testWidgets('search narrows to matching lines', (tester) async {
      await seed(tester);
      await tester.pumpWidget(app());
      await settle(tester);

      await tester.tap(find.bySemanticsLabel('Search saved'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'fact');
      await settle(tester);
      expect(find.text('Fact 1'), findsOneWidget);
      expect(find.text('Quote q'), findsNothing);
      // The revisit steps aside while searching.
      expect(find.text('FROM YOUR SAVED, 3 WEEKS AGO'), findsNothing);
      await teardown(tester);
    });
  });
}
