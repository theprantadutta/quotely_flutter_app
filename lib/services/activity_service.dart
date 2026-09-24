import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';

/// Per-day counts of what was read. A day counts toward the streak when at
/// least one item was viewed.
@immutable
class DayActivity {
  final int quotes;
  final int scenes;
  final int facts;
  const DayActivity({this.quotes = 0, this.scenes = 0, this.facts = 0});

  int get total => quotes + scenes + facts;

  Map<String, int> toJson() => {'q': quotes, 's': scenes, 'f': facts};

  factory DayActivity.fromJson(Map<String, dynamic> j) => DayActivity(
    quotes: j['q'] as int? ?? 0,
    scenes: j['s'] as int? ?? 0,
    facts: j['f'] as int? ?? 0,
  );
}

/// Summary for the You screen's streak card.
@immutable
class ActivitySummary {
  final int streak;
  final int quotes;
  final int scenes;
  final int facts;

  /// Monday-first, this week: true = read that day.
  final List<bool> week;

  /// Index of today in [week] (0 = Monday).
  final int todayIndex;

  const ActivitySummary({
    required this.streak,
    required this.quotes,
    required this.scenes,
    required this.facts,
    required this.week,
    required this.todayIndex,
  });
}

/// Records what the user views, for the streak card. Views are de-duplicated
/// per session and flushed to SharedPreferences in small batches.
class ActivityService {
  ActivityService._();
  static final ActivityService instance = ActivityService._();

  static final _day = DateFormat('yyyy-MM-dd');
  static const _keepDays = 400;

  final Set<String> _seen = {};
  final Map<String, DayActivity> _log = {};
  bool _loaded = false;
  Timer? _flush;

  /// Bumped whenever the log changes, so the You screen can listen.
  final ValueNotifier<int> changes = ValueNotifier(0);

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kActivityLogKey);
    if (raw != null) {
      final map = json.decode(raw) as Map<String, dynamic>;
      map.forEach(
        (k, v) => _log[k] = DayActivity.fromJson(v as Map<String, dynamic>),
      );
    }
    _loaded = true;
  }

  /// Call when a quote/scene/fact is shown. [kind] is 'quote'|'scene'|'fact'.
  void markViewed(String kind, String id) {
    final key = '$kind:$id';
    if (!_seen.add(key)) return;
    _load().then((_) {
      final today = _day.format(DateTime.now());
      final d = _log[today] ?? const DayActivity();
      _log[today] = DayActivity(
        quotes: d.quotes + (kind == 'quote' ? 1 : 0),
        scenes: d.scenes + (kind == 'scene' ? 1 : 0),
        facts: d.facts + (kind == 'fact' ? 1 : 0),
      );
      _flush?.cancel();
      _flush = Timer(const Duration(seconds: 2), _save);
    });
  }

  Future<void> _save() async {
    final cutoff = _day.format(
      DateTime.now().subtract(const Duration(days: _keepDays)),
    );
    _log.removeWhere((k, _) => k.compareTo(cutoff) < 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kActivityLogKey,
      json.encode(_log.map((k, v) => MapEntry(k, v.toJson()))),
    );
    changes.value++;
  }

  Future<ActivitySummary> summary() async {
    await _load();
    final now = DateTime.now();
    bool active(DateTime d) => (_log[_day.format(d)]?.total ?? 0) > 0;

    // Today not read yet doesn't break the streak until the day is over.
    var streak = 0;
    var cursor = active(now) ? now : now.subtract(const Duration(days: 1));
    while (active(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final monday = now.subtract(Duration(days: now.weekday - 1));
    final week = [
      for (var i = 0; i < 7; i++) active(monday.add(Duration(days: i))),
    ];
    var q = 0, s = 0, f = 0;
    for (final d in _log.values) {
      q += d.quotes;
      s += d.scenes;
      f += d.facts;
    }
    return ActivitySummary(
      streak: streak,
      quotes: q,
      scenes: s,
      facts: f,
      week: week,
      todayIndex: now.weekday - 1,
    );
  }
}
