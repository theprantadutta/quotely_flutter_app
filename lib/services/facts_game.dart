import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';

/// Questions per day in the True or False game.
const int kFactsPerDay = 10;

const kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.pranta.quotely';
const kAppStoreUrl = 'https://apps.apple.com/app/id6778280010';

/// The local calendar day of [t] as yyyy-MM-dd. The game's day is the
/// user's own day: it turns over at their midnight, wherever they are.
String factsDayKey(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year.toString().padLeft(4, '0')}-${two(l.month)}-${two(l.day)}';
}

/// Whole calendar days from day key [from] to [to] (both yyyy-MM-dd).
/// Counted on UTC dates, so a daylight-saving change never makes a day
/// 23 or 25 hours long.
int factsDaysBetween(String from, String to) {
  DateTime parse(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  return parse(to).difference(parse(from)).inDays;
}

/// One day's round: each answer in order, true for right.
@immutable
class FactsRound {
  final String day;
  final List<bool> results;

  const FactsRound({required this.day, this.results = const []});

  int get answered => results.length;
  int get correct => results.where((r) => r).length;
  bool get complete => answered >= kFactsPerDay;

  FactsRound record(bool right) {
    if (complete) return this;
    return FactsRound(day: day, results: [...results, right]);
  }

  Map<String, Object> toJson() => {
    'date': day,
    'answered': answered,
    'correct': correct,
    'results': results,
  };

  /// Reads a stored round. Rounds saved before the per-answer list only
  /// have the counts; their dots come out rights first.
  static FactsRound? fromJson(Map<String, dynamic> j) {
    final day = j['date'];
    if (day is! String) return null;
    final raw = j['results'];
    if (raw is List) {
      return FactsRound(
        day: day,
        results: [for (final r in raw.take(kFactsPerDay)) r == true],
      );
    }
    final answered = (j['answered'] as int? ?? 0).clamp(0, kFactsPerDay);
    final correct = (j['correct'] as int? ?? 0).clamp(0, answered);
    return FactsRound(
      day: day,
      results: [for (var i = 0; i < answered; i++) i < correct],
    );
  }
}

/// Consecutive days with the round completed, and the best run so far.
@immutable
class FactsStreak {
  /// The run as of [lastDay]; see [currentOn] for the run as of today.
  final int count;
  final int best;

  /// The last day a round was completed (yyyy-MM-dd).
  final String? lastDay;

  const FactsStreak({this.count = 0, this.best = 0, this.lastDay});

  /// The streak to show on [today]: the run is alive until a whole day
  /// passes without a completed round.
  int currentOn(String today) {
    final last = lastDay;
    if (last == null) return 0;
    final gap = factsDaysBetween(last, today);
    // A negative gap means the clock or the time zone went backwards
    // (flying west across the date line): keep the run rather than punish.
    return gap <= 1 ? count : 0;
  }

  /// Records today's completed round. Completing twice in a day, or on a
  /// day before [lastDay], changes nothing.
  FactsStreak complete(String today) {
    final last = lastDay;
    if (last != null && factsDaysBetween(last, today) <= 0) return this;
    final next = last != null && factsDaysBetween(last, today) == 1
        ? count + 1
        : 1;
    return FactsStreak(
      count: next,
      best: next > best ? next : best,
      lastDay: today,
    );
  }

  Map<String, Object?> toJson() => {
    'count': count,
    'best': best,
    'last': lastDay,
  };

  static FactsStreak fromJson(Map<String, dynamic> j) => FactsStreak(
    count: j['count'] as int? ?? 0,
    best: j['best'] as int? ?? 0,
    lastDay: j['last'] as String?,
  );
}

/// The line under the score.
String factsVerdict(int correct) {
  if (correct >= 8) return 'Sharp!';
  if (correct >= 5) return 'Not bad';
  return 'Tomorrow’s yours';
}

/// "6-day streak", or null when there is no run to show.
String? factsStreakLabel(int streak) =>
    streak > 0 ? '$streak-day streak' : null;

/// The store link for the platform the user is on.
String factsStoreUrl(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
    ? kAppStoreUrl
    : kPlayStoreUrl;

/// The text sent with the score card. It never names the answers.
String factsScoreShareText({
  required int correct,
  required int streak,
  required TargetPlatform platform,
  int total = kFactsPerDay,
}) {
  final streakLine = streak > 1 ? ' $streak days in a row.' : '';
  return 'I got $correct/$total on today’s True or False in Quotely.'
      '$streakLine Can you beat it?\n\n${factsStoreUrl(platform)}\n';
}

/// Local storage for the round and the streak.
class FactsGameStore {
  const FactsGameStore._();

  static Future<FactsRound> loadRound(String today) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kFactsGameProgressKey);
    if (raw != null) {
      try {
        final round = FactsRound.fromJson(
          json.decode(raw) as Map<String, dynamic>,
        );
        if (round != null && round.day == today) return round;
      } catch (_) {}
    }
    return FactsRound(day: today);
  }

  static Future<void> saveRound(FactsRound round) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kFactsGameProgressKey, json.encode(round.toJson()));
  }

  static Future<FactsStreak> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kFactsGameStreakKey);
    if (raw == null) return const FactsStreak();
    try {
      return FactsStreak.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const FactsStreak();
    }
  }

  static Future<void> saveStreak(FactsStreak streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kFactsGameStreakKey, json.encode(streak.toJson()));
  }
}
