import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the user answered to "Enjoying Quotely?".
enum ReviewPromptAnswer {
  yes('yes'),
  notReally('not_really'),
  later('later');

  const ReviewPromptAnswer(this.wire);
  final String wire;
}

/// When to ask "Enjoying Quotely?". All state lives in SharedPreferences;
/// the clock is injectable so the schedule is testable.
///
/// - **Usage:** every app open (start and resume) is recorded; the number of
///   distinct local days with an open is counted, and the first open kept.
/// - **First ask:** after [minActiveDays] distinct days of use, or
///   [minDaysSinceFirstOpen] days since the first open, whichever comes first.
/// - **Re-ask:** at least [reaskAfter] after the last time it was shown,
///   whatever the answer (Not really and Later included).
/// - **After "Yes!":** not again for [quietAfterYes].
/// - **At most [maxAsks] times ever.**
/// - At most once per app session (the caller keeps that flag).
class ReviewPromptPolicy {
  ReviewPromptPolicy(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const minActiveDays = 15;
  static const minDaysSinceFirstOpen = Duration(days: 30);
  static const reaskAfter = Duration(days: 30);
  static const quietAfterYes = Duration(days: 120);
  static const maxAsks = 4;

  @visibleForTesting
  static const kFirstOpen = 'review-prompt-first-open';
  @visibleForTesting
  static const kActiveDays = 'review-prompt-active-days';
  @visibleForTesting
  static const kLastActiveDay = 'review-prompt-last-active-day';
  @visibleForTesting
  static const kTimesAsked = 'review-prompt-times-asked';
  @visibleForTesting
  static const kLastAsked = 'review-prompt-last-asked';
  @visibleForTesting
  static const kLastYes = 'review-prompt-last-yes';
  @visibleForTesting
  static const kLastAnswer = 'review-prompt-last-answer';

  DateTime? _date(String key) {
    final raw = _prefs.getString(key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static String _day(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  DateTime? get firstOpen => _date(kFirstOpen);
  int get activeDays => _prefs.getInt(kActiveDays) ?? 0;
  int get timesAsked => _prefs.getInt(kTimesAsked) ?? 0;
  DateTime? get lastAsked => _date(kLastAsked);
  DateTime? get lastYes => _date(kLastYes);
  String? get lastAnswer => _prefs.getString(kLastAnswer);

  /// Records an app open: sets the first-open date once, and counts today
  /// as an active day if it isn't already.
  Future<void> recordAppOpen() async {
    final now = _clock();
    if (firstOpen == null) {
      await _prefs.setString(kFirstOpen, now.toIso8601String());
    }
    final today = _day(now);
    if (_prefs.getString(kLastActiveDay) != today) {
      await _prefs.setString(kLastActiveDay, today);
      await _prefs.setInt(kActiveDays, activeDays + 1);
    }
  }

  /// Whether the prompt is due now (ignoring the per-session limit).
  bool get isDue {
    final now = _clock();
    final first = firstOpen;
    if (first == null) return false;
    final usedEnough =
        activeDays >= minActiveDays ||
        now.difference(first) >= minDaysSinceFirstOpen;
    if (!usedEnough) return false;
    if (timesAsked >= maxAsks) return false;
    final asked = lastAsked;
    if (asked != null && now.difference(asked) < reaskAfter) return false;
    final yes = lastYes;
    if (yes != null && now.difference(yes) < quietAfterYes) return false;
    return true;
  }

  /// Call when the prompt is shown: it counts toward [maxAsks] and starts
  /// the [reaskAfter] wait whatever the answer.
  Future<void> recordShown() async {
    await _prefs.setInt(kTimesAsked, timesAsked + 1);
    await _prefs.setString(kLastAsked, _clock().toIso8601String());
  }

  Future<void> recordAnswer(ReviewPromptAnswer answer) async {
    await _prefs.setString(kLastAnswer, answer.wire);
    if (answer == ReviewPromptAnswer.yes) {
      await _prefs.setString(kLastYes, _clock().toIso8601String());
    }
  }
}
