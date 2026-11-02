import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/quote_widget_bridge.dart';
import 'package:quotely_flutter_app/dtos/media_title_dto.dart';
import 'package:quotely_flutter_app/dtos/scene_quote_dto.dart';
import 'package:quotely_flutter_app/services/home_widget_store.dart';
import 'package:quotely_flutter_app/services/saved_widget_service.dart';
import 'package:quotely_flutter_app/services/scene_widget_service.dart';
import 'package:quotely_flutter_app/services/widget_analytics.dart';
import 'package:quotely_flutter_app/theme/tokens.dart';

const _channel = MethodChannel('home_widget');

SavedWidgetQuote _q(String id, int day, [String? text]) => SavedWidgetQuote(
  id: id,
  text: text ?? 'Quote $id',
  author: 'Author $id',
  added: DateTime.utc(2026, 1, day),
);

/// A stand-in for home_widget's storage: what was saved, and every call.
class _FakePlugin {
  final data = <String, Object?>{};
  final calls = <MethodCall>[];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          final args = (call.arguments as Map?)?.cast<String, Object?>();
          switch (call.method) {
            case 'saveWidgetData':
              data[args!['id']! as String] = args['data'];
              return true;
            case 'getWidgetData':
              return data[args!['id']! as String] ?? args['defaultValue'];
            case 'updateWidget':
              return true;
          }
          return null;
        });
  }

  List<String> get redrawn => [
    for (final c in calls)
      if (c.method == 'updateWidget')
        (c.arguments as Map)['qualifiedAndroidName'] as String,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('From your saved: picking by date', () {
    final saved = [_q('a', 1), _q('b', 2), _q('c', 3)];

    test('one quote a day, walking the list in the order it was saved', () {
      final day = DateTime(2026, 11, 2);
      final next = DateTime(2026, 11, 3);
      final first = SavedWidgetService.pickFor(saved, day)!;
      final second = SavedWidgetService.pickFor(saved, next)!;
      expect(first.id, isNot(second.id));
      final ids = saved.map((q) => q.id).toList();
      expect(ids.indexOf(second.id), (ids.indexOf(first.id) + 1) % 3);
    });

    test('the same for the whole day and in any database order', () {
      final morning = DateTime(2026, 11, 2, 0, 1);
      final night = DateTime(2026, 11, 2, 23, 59);
      expect(
        SavedWidgetService.pickFor(saved, morning)!.id,
        SavedWidgetService.pickFor(saved.reversed, night)!.id,
      );
    });

    test('days are counted on the calendar, across daylight saving', () {
      // 1 January 2026 is day 0; 2 November is day 305.
      expect(HomeWidgetStore.dayNumber(DateTime(2026)), 0);
      expect(HomeWidgetStore.dayNumber(DateTime(2026, 11, 2, 23)), 305);
      expect(HomeWidgetStore.dayNumber(DateTime(2026, 3, 30)), 88);
      expect(SavedWidgetService.pickFor(saved, DateTime(2026))!.id, 'a');
      expect(SavedWidgetService.pickFor(saved, DateTime(2026, 1, 2))!.id, 'b');
    });

    test('nothing saved: no pick, and no quotes for the widget', () {
      expect(SavedWidgetService.pickFor(const [], DateTime(2026, 11, 2)), null);
      final payload = SavedWidgetService.payload(
        const [],
        DateTime(2026, 11, 2, 15),
      );
      expect(payload['start'], '2026-11-02');
      expect(payload['quotes'], isEmpty);
    });

    test('blank quotes are never picked', () {
      final pick = SavedWidgetService.pickFor([
        _q('x', 1, '   '.trim()),
        _q('y', 2),
      ], DateTime(2026, 11, 2));
      expect(pick!.id, 'y');
    });

    test('the payload holds the next 30 days, each the day\'s pick', () {
      final today = DateTime(2026, 11, 2, 9);
      final payload = SavedWidgetService.payload(saved, today);
      final quotes = (payload['quotes']! as List).cast<Map<String, Object>>();
      expect(quotes, hasLength(SavedWidgetService.horizon));
      for (var i = 0; i < quotes.length; i++) {
        final pick = SavedWidgetService.pickFor(
          saved,
          DateTime(2026, 11, 2 + i),
        )!;
        expect(quotes[i], {'t': pick.text, 'a': pick.author});
      }
    });
  });

  group('what gets saved', () {
    late _FakePlugin plugin;

    setUp(() {
      HomeWidgetStore.debugSupported = true;
      HomeWidgetStore.debugReset();
      SavedWidgetService.instance.debugReset();
      SceneWidgetService.instance.debugReset();
      plugin = _FakePlugin()..install();
    });

    tearDown(() {
      HomeWidgetStore.debugSupported = null;
      HomeWidgetStore.debugPosterBytes = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test('From your saved: the picks, the count and the glow', () async {
      final now = DateTime(2026, 11, 2, 18);
      await SavedWidgetService.instance.update([
        _q('a', 1),
        _q('b', 2),
      ], now: now);

      final days = jsonDecode(plugin.data['saved_days']! as String) as Map;
      expect(days['start'], '2026-11-02');
      expect((days['quotes'] as List).first, {
        't': SavedWidgetService.pickFor([_q('a', 1), _q('b', 2)], now)!.text,
        'a': SavedWidgetService.pickFor([_q('a', 1), _q('b', 2)], now)!.author,
      });
      expect(plugin.data['saved_count'], 2);
      expect(plugin.data['glow_days'], isA<String>());
      expect(plugin.redrawn, [
        'com.pranta.quotely.widget.SavedQuoteWidgetProvider',
      ]);

      // The same list on the same day saves nothing new...
      await SavedWidgetService.instance.update([
        _q('b', 2),
        _q('a', 1),
      ], now: now);
      expect(plugin.redrawn, hasLength(1));
      // ...unsaving one does.
      await SavedWidgetService.instance.update([_q('a', 1)], now: now);
      expect(plugin.redrawn, hasLength(2));
      expect(plugin.data['saved_count'], 1);
    });

    test('From your saved, empty: a zero count the widget shows the '
        'hint for', () async {
      await SavedWidgetService.instance.update(
        const [],
        now: DateTime(2026, 11, 2),
      );
      expect(plugin.data['saved_count'], 0);
      final days = jsonDecode(plugin.data['saved_days']! as String) as Map;
      expect(days['quotes'], isEmpty);
      expect(plugin.redrawn, hasLength(1));
    });

    test('Scene of the Day: the line, who said it, the title, and no '
        'poster when none can be had', () async {
      HomeWidgetStore.debugPosterBytes = (url) async =>
          throw StateError('offline');
      plugin.data['scene_poster_url'] = 'https://old/poster.jpg';
      await SceneWidgetService.instance.update(
        scene: SceneOfTheDayDto(
          id: 1,
          sceneDate: DateTime.utc(2026, 11, 2),
          sceneQuote: SceneQuoteDto(
            id: 's1',
            content: ' I\'m gonna make him an offer he can\'t refuse. ',
            titleId: 't1',
            titleName: 'The Godfather',
            titleType: MediaType.movie,
            posterUrl: 'https://img/godfather.jpg',
            characterId: 'c1',
            characterName: 'Vito Corleone',
            tags: const [],
            dateAdded: DateTime.utc(2026),
            dateModified: DateTime.utc(2026),
          ),
        ),
        fallbackPosterUrl: 'https://img/fallback.jpg',
        now: DateTime(2026, 11, 2, 8),
      );

      expect(plugin.data['scene_eyebrow'], 'SCENE · THE GODFATHER');
      expect(
        plugin.data['scene_text'],
        "I'm gonna make him an offer he can't refuse.",
      );
      expect(plugin.data['scene_character'], 'Vito Corleone');
      expect(plugin.data['scene_title'], 'The Godfather');
      expect(plugin.data['scene_title_id'], 't1');
      expect(plugin.data['scene_date'], '2026-11-02');
      // Both posters failed: cleared, so the widget shows the glow.
      expect(plugin.data['scene_poster'], isNull);
      expect(plugin.data['scene_poster_url'], isNull);
      expect(plugin.data['glow_days'], isA<String>());
      expect(plugin.redrawn, [
        'com.pranta.quotely.widget.SceneOfTheDayWidgetProvider',
      ]);
    });
  });

  test('glow days are the glow the app paints on each day', () {
    final today = DateTime(2026, 11, 2, 21);
    final glow = HomeWidgetStore.glowDays(today);
    expect(glow['start'], '2026-11-02');
    final light = glow['light']! as List<int>;
    final dark = glow['dark']! as List<int>;
    expect(light, hasLength(HomeWidgetStore.glowHorizon));
    expect(HomeWidgetStore.glowHorizon % 5, 0);
    final lightTokens = QuotelyTokens.of(Brightness.light, QAccent.teal);
    final darkTokens = QuotelyTokens.of(Brightness.dark, QAccent.teal);
    for (var i = 0; i < light.length; i++) {
      final day = DateTime(2026, 11, 2 + i);
      expect(light[i], lightTokens.glowFor(day).toARGB32());
      expect(dark[i], darkTokens.glowFor(day).toARGB32());
    }
  });

  group('analytics', () {
    test('Android placement events are read back by kind', () {
      expect(
        WidgetAnalytics.parseEvents(
          'placed:saved,removed:qotd,junk,placed:nope,placed:scene',
        ),
        [
          ('widget_placed', QuotelyWidgetKind.saved),
          ('widget_removed', QuotelyWidgetKind.qotd),
          ('widget_placed', QuotelyWidgetKind.scene),
        ],
      );
      expect(WidgetAnalytics.parseEvents(null), isEmpty);
    });

    test('iOS placements come from what is installed now vs before', () {
      expect(
        WidgetAnalytics.diffInstalled(
          {QuotelyWidgetKind.qotd},
          {QuotelyWidgetKind.saved},
        ),
        [
          ('widget_placed', QuotelyWidgetKind.saved),
          ('widget_removed', QuotelyWidgetKind.qotd),
        ],
      );
    });

    test('installed widgets are recognised on both platforms', () {
      expect(
        QuotelyWidgetKind.fromInstalled(iOSKind: 'QuotelySceneWidget'),
        QuotelyWidgetKind.scene,
      );
      expect(
        QuotelyWidgetKind.fromInstalled(
          androidClassName: '.widget.SavedQuoteWidgetProvider',
        ),
        QuotelyWidgetKind.saved,
      );
    });
  });

  test('a widget tap is attributed to the widget it came from', () {
    expect(
      widgetKindOf(Uri.parse('quotely://widget/saved?homeWidget&kind=saved')),
      QuotelyWidgetKind.saved,
    );
    expect(
      widgetKindOf(Uri.parse('quotely://widget/home?homeWidget&kind=scene')),
      QuotelyWidgetKind.scene,
    );
    // Widgets drawn by the previous version had no kind.
    expect(
      widgetKindOf(Uri.parse('quotely://widget/home?homeWidget')),
      QuotelyWidgetKind.qotd,
    );
  });
}
