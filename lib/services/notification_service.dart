import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/notification_keys.dart';
import '../constants/notification_types.dart';
import '../constants/shared_preference_keys.dart';

typedef TopicAction = Future<void> Function(String topic);

class NotificationService {
  /// [subscribe] and [unsubscribe] replace the FCM calls (tests).
  NotificationService({TopicAction? subscribe, TopicAction? unsubscribe})
    : _subscribe = subscribe,
      _unsubscribe = unsubscribe;

  final TopicAction? _subscribe;
  final TopicAction? _unsubscribe;

  Future<void> subscribeToTopic(String topic) async {
    final subscribe = _subscribe;
    if (subscribe != null) return subscribe(topic);
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    final unsubscribe = _unsubscribe;
    if (unsubscribe != null) return unsubscribe(topic);
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  // --- Defaults for unset preferences -----------------------------------------
  // Installs that ran an earlier version started with every kind on and keep
  // that: their stored values win, and a key they never stored still reads as
  // on. New installs start calm, with only Quote of the day on.

  static const _calmDefaults = 'calm';
  static const _legacyDefaults = 'legacy';

  /// The kinds a new install starts with.
  static const Set<String> calmDefaultOn = {kNotificationQuoteOfTheDay};

  /// Keys only an install that has already run (an older version) can have.
  static List<String> get _priorInstallKeys => [
    kNotificationsInitializedKey,
    kHasSeenNotificationPrompt,
    kNotificationEnabled,
    kOnboardingShownKey,
    kHasSelectedInterestsKey,
    for (final t in kNotificationTypes) t.prefKey,
  ];

  /// Whether this install uses the calm defaults. Decided on the first call
  /// and stored, so the answer never changes: any trace of an earlier run
  /// means legacy (all on, exactly as before), a clean slate means calm.
  static bool usesCalmDefaults(SharedPreferences prefs) {
    final stored = prefs.getString(kNotificationDefaultsKey);
    if (stored != null) return stored == _calmDefaults;
    // The in-memory cache updates synchronously; the disk write follows.
    final calm = !_priorInstallKeys.any(prefs.containsKey);
    unawaited(_store(prefs, calm));
    return calm;
  }

  static Future<bool> _store(SharedPreferences prefs, bool calm) =>
      prefs.setString(
        kNotificationDefaultsKey,
        calm ? _calmDefaults : _legacyDefaults,
      );

  /// Decides and persists [usesCalmDefaults] now. Called from main() before
  /// the first frame, so onboarding can't be mistaken for an earlier run.
  static Future<void> resolveDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(kNotificationDefaultsKey)) return;
      await _store(prefs, !_priorInstallKeys.any(prefs.containsKey));
    } catch (e) {
      debugPrint('Could not resolve notification defaults: $e');
    }
  }

  /// What a notification preference with no stored value means. The master
  /// switch defaults on for everyone.
  static bool defaultFor(SharedPreferences prefs, String key) {
    if (key == kNotificationEnabled) return true;
    return !usesCalmDefaults(prefs) || calmDefaultOn.contains(key);
  }

  /// A notification preference: the stored value, else [defaultFor].
  static bool isEnabled(SharedPreferences prefs, String key) =>
      prefs.getBool(key) ?? defaultFor(prefs, key);

  /// `title_<slug>` topics for every followed title.
  static Future<List<String>> followedTitleTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kFollowedTitleSlugsKey);
    if (raw == null) return const [];
    final map = json.decode(raw) as Map<String, dynamic>;
    return [
      for (final slug in map.values) '$kNotificationTitleTopicPrefix$slug',
    ];
  }

  /// Every fixed topic the app can subscribe to (the per-title ones come
  /// from [followedTitleTopics]).
  static List<String> get allTopics => [
    kNotificationAllTopic,
    for (final t in kNotificationTypes)
      if (t.topic != null) t.topic!,
  ];

  Future<void> subscribeToAllTopic() async {
    for (final topic in allTopics) {
      await subscribeToTopic(topic);
    }
    await syncFollowedTitleTopics(true);
  }

  Future<void> unsubscribeFromAllTopic() async {
    for (final topic in allTopics) {
      await unsubscribeFromTopic(topic);
    }
    await syncFollowedTitleTopics(false);
  }

  /// Subscribes to (or leaves) every followed title's topic.
  Future<void> syncFollowedTitleTopics(bool enabled) async {
    for (final topic in await followedTitleTopics()) {
      enabled
          ? await subscribeToTopic(topic)
          : await unsubscribeFromTopic(topic);
    }
  }

  /// Subscribes to each topic whose preference is on. A missing preference
  /// follows [defaultFor]: on for existing installs (so kinds added later,
  /// such as Friday night lines, reach them), only Quote of the day for new
  /// ones. Runs on every launch; never unsubscribes.
  Future<void> enableNotificationsBasedOnPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!isEnabled(preferences, kNotificationEnabled)) {
      if (kDebugMode) {
        print('Global notifications are disabled. Skipping subscriptions.');
      }
      return;
    }
    for (final type in kNotificationTypes) {
      if (!isEnabled(preferences, type.prefKey)) continue;
      if (type.topic != null) {
        await subscribeToTopic(type.topic!);
      } else if (type.prefKey == kNotificationFollowedTitles) {
        await syncFollowedTitleTopics(true);
      }
    }
  }

  /// Once per install, stores the default for every notification preference
  /// that has no value yet (stored values are never overwritten), then
  /// subscribes accordingly.
  Future<void> initializeNotificationPreferencesOnce() async {
    final preferences = await SharedPreferences.getInstance();
    await enableNotificationsBasedOnPreferences();
    if (preferences.getBool(kNotificationsInitializedKey) == true) return;

    for (final key in [
      kNotificationEnabled,
      for (final type in kNotificationTypes) type.prefKey,
    ]) {
      if (preferences.containsKey(key)) continue;
      await preferences.setBool(key, defaultFor(preferences, key));
    }
    await preferences.setBool(kNotificationsInitializedKey, true);
    await enableNotificationsBasedOnPreferences();
  }

  // --- Quiet hours ------------------------------------------------------------
  // Enforced locally: foreground notifications inside the window are not
  // shown. TODO(backend): send the window with the FCM token so scheduled
  // pushes skip it server-side too.

  static const int defaultQuietStart = 22 * 60;
  static const int defaultQuietEnd = 7 * 60;

  static Future<({bool enabled, int start, int end})> quietHours() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(kQuietHoursEnabledKey) ?? true,
      start: prefs.getInt(kQuietHoursStartKey) ?? defaultQuietStart,
      end: prefs.getInt(kQuietHoursEndKey) ?? defaultQuietEnd,
    );
  }

  static Future<bool> isQuietNow([DateTime? at]) async {
    final q = await quietHours();
    if (!q.enabled) return false;
    final now = at ?? DateTime.now();
    final minute = now.hour * 60 + now.minute;
    // A window can wrap midnight (22:00 → 07:00).
    return q.start <= q.end
        ? minute >= q.start && minute < q.end
        : minute >= q.start || minute < q.end;
  }
}
