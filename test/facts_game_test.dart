import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/services/facts_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('day keys', () {
    test('use the local calendar day, turning over at local midnight', () {
      expect(factsDayKey(DateTime(2026, 11, 16, 23, 59, 59)), '2026-11-16');
      expect(factsDayKey(DateTime(2026, 11, 17, 0, 0, 1)), '2026-11-17');
      expect(factsDayKey(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('a UTC instant is read in the local time zone', () {
      final instant = DateTime.utc(2026, 11, 16, 23, 30);
      final local = instant.toLocal();
      final expected =
          '${local.year}-${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}';
      expect(factsDayKey(instant), expected);
    });

    test('days between are calendar days, across DST and year ends', () {
      expect(factsDaysBetween('2026-11-16', '2026-11-17'), 1);
      expect(factsDaysBetween('2026-11-16', '2026-11-16'), 0);
      expect(factsDaysBetween('2026-11-17', '2026-11-16'), -1);
      // US and EU daylight-saving changes: 23 and 25 hour days.
      expect(factsDaysBetween('2026-03-07', '2026-03-09'), 2);
      expect(factsDaysBetween('2026-03-28', '2026-03-29'), 1);
      expect(factsDaysBetween('2026-10-24', '2026-10-26'), 2);
      expect(factsDaysBetween('2026-10-31', '2026-11-01'), 1);
      expect(factsDaysBetween('2026-12-31', '2027-01-01'), 1);
      expect(factsDaysBetween('2028-02-28', '2028-03-01'), 2);
      expect(factsDaysBetween('2027-02-28', '2027-03-01'), 1);
    });
  });

  group('streak', () {
    test('grows on consecutive days and tracks the best', () {
      var s = const FactsStreak();
      s = s.complete('2026-11-14');
      s = s.complete('2026-11-15');
      s = s.complete('2026-11-16');
      expect(s.count, 3);
      expect(s.best, 3);
      expect(s.currentOn('2026-11-16'), 3);
    });

    test('completing twice on the same day counts once', () {
      final s = const FactsStreak().complete('2026-11-16');
      expect(s.complete('2026-11-16'), same(s));
      expect(s.count, 1);
    });

    test('stays alive through the next day, then shows zero', () {
      final s = const FactsStreak(count: 6, best: 6, lastDay: '2026-11-16');
      expect(s.currentOn('2026-11-16'), 6);
      expect(s.currentOn('2026-11-17'), 6);
      expect(s.currentOn('2026-11-18'), 0);
    });

    test('a missed day resets it, keeping the best', () {
      final s = const FactsStreak(
        count: 6,
        best: 9,
        lastDay: '2026-11-14',
      ).complete('2026-11-16');
      expect(s.count, 1);
      expect(s.best, 9);
    });

    test('a new best replaces the old one', () {
      final s = const FactsStreak(
        count: 9,
        best: 9,
        lastDay: '2026-11-15',
      ).complete('2026-11-16');
      expect(s.count, 10);
      expect(s.best, 10);
    });

    test('runs across month, year and daylight-saving boundaries', () {
      var s = const FactsStreak();
      for (final d in [
        '2026-10-31',
        '2026-11-01',
        '2026-11-02',
        '2026-12-31',
      ]) {
        s = s.complete(d);
      }
      // Nov 2 to Dec 31 broke it.
      expect(s.count, 1);
      expect(s.best, 3);
      s = s.complete('2027-01-01');
      expect(s.count, 2);

      var dst = const FactsStreak();
      for (final d in ['2026-03-07', '2026-03-08', '2026-03-09']) {
        dst = dst.complete(d);
      }
      expect(dst.count, 3);
    });

    test('a day that goes backwards (flying west) never breaks it', () {
      final s = const FactsStreak(count: 4, best: 4, lastDay: '2026-11-17');
      expect(s.currentOn('2026-11-16'), 4);
      expect(s.complete('2026-11-16'), same(s));
    });

    test('is played in local days: the same instants can differ by zone', () {
      // A player in UTC-8 finishing at 23:00 on the 16th and 23:00 on the
      // 17th has a 2-day run. Those instants are 07:00 on the 17th and
      // 18th in UTC: also consecutive. Keys come from the local day.
      final la1 = DateTime.utc(
        2026,
        11,
        17,
        7,
      ).subtract(const Duration(hours: 8));
      final la2 = la1.add(const Duration(days: 1));
      String key(DateTime wall) =>
          '${wall.year}-${wall.month.toString().padLeft(2, '0')}-'
          '${wall.day.toString().padLeft(2, '0')}';
      final s = const FactsStreak().complete(key(la1)).complete(key(la2));
      expect(key(la1), '2026-11-16');
      expect(s.count, 2);
    });

    test('round-trips through JSON', () {
      const s = FactsStreak(count: 3, best: 7, lastDay: '2026-11-16');
      final back = FactsStreak.fromJson(
        json.decode(json.encode(s.toJson())) as Map<String, dynamic>,
      );
      expect(back.count, 3);
      expect(back.best, 7);
      expect(back.lastDay, '2026-11-16');
    });
  });

  group('round', () {
    test('records answers in order and stops at the day\'s 10', () {
      var r = const FactsRound(day: '2026-11-17');
      for (var i = 0; i < 12; i++) {
        r = r.record(i.isEven);
      }
      expect(r.answered, kFactsPerDay);
      expect(r.correct, 5);
      expect(r.complete, isTrue);
      expect(r.results.first, isTrue);
      expect(r.results[1], isFalse);
    });

    test('a partial day is not complete', () {
      final r = const FactsRound(day: '2026-11-17').record(true).record(false);
      expect(r.complete, isFalse);
      expect(r.answered, 2);
    });

    test('reads rounds saved before the per-answer list', () {
      final r = FactsRound.fromJson({
        'date': '2026-11-17',
        'answered': 4,
        'correct': 3,
      })!;
      expect(r.results, [true, true, true, false]);
    });
  });

  group('store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keeps today\'s round and drops yesterday\'s', () async {
      final r = const FactsRound(day: '2026-11-17').record(true).record(false);
      await FactsGameStore.saveRound(r);
      final same = await FactsGameStore.loadRound('2026-11-17');
      expect(same.results, [true, false]);
      final next = await FactsGameStore.loadRound('2026-11-18');
      expect(next.answered, 0);
      expect(next.day, '2026-11-18');
    });

    test('survives a corrupt value', () async {
      SharedPreferences.setMockInitialValues({
        kFactsGameProgressKey: 'not json',
        kFactsGameStreakKey: '{',
      });
      expect((await FactsGameStore.loadRound('2026-11-17')).answered, 0);
      expect((await FactsGameStore.loadStreak()).count, 0);
    });

    test('saves and loads the streak', () async {
      await FactsGameStore.saveStreak(
        const FactsStreak(count: 2, best: 5, lastDay: '2026-11-17'),
      );
      final s = await FactsGameStore.loadStreak();
      expect(s.best, 5);
      expect(s.currentOn('2026-11-18'), 2);
    });
  });

  group('copy', () {
    test('verdicts', () {
      expect(factsVerdict(10), 'Sharp!');
      expect(factsVerdict(8), 'Sharp!');
      expect(factsVerdict(7), 'Not bad');
      expect(factsVerdict(5), 'Not bad');
      expect(factsVerdict(4), 'Tomorrow’s yours');
      expect(factsVerdict(0), 'Tomorrow’s yours');
    });

    test('streak label', () {
      expect(factsStreakLabel(6), '6-day streak');
      expect(factsStreakLabel(0), isNull);
    });

    test('share text links the store for the platform', () {
      final android = factsScoreShareText(
        correct: 8,
        streak: 6,
        platform: TargetPlatform.android,
      );
      expect(android, contains('8/10'));
      expect(android, contains('6 days in a row'));
      expect(android, contains(kPlayStoreUrl));
      expect(android, isNot(contains(kAppStoreUrl)));

      final ios = factsScoreShareText(
        correct: 3,
        streak: 1,
        platform: TargetPlatform.iOS,
      );
      expect(ios, contains('3/10'));
      expect(ios, contains(kAppStoreUrl));
      expect(ios, isNot(contains(kPlayStoreUrl)));
      expect(ios, isNot(contains('in a row')));
    });

    test('store links', () {
      expect(
        kPlayStoreUrl,
        'https://play.google.com/store/apps/details?id=com.pranta.quotely',
      );
      expect(kAppStoreUrl, 'https://apps.apple.com/app/id6778280010');
      expect(factsStoreUrl(TargetPlatform.macOS), kAppStoreUrl);
      expect(factsStoreUrl(TargetPlatform.fuchsia), kPlayStoreUrl);
    });
  });
}
