import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/notification_keys.dart';
import '../constants/notification_types.dart';
import '../constants/shared_preference_keys.dart';

class NotificationService {
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

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

  /// Subscribes to each topic whose preference is on (missing = on, so new
  /// kinds such as Friday night lines are opt-in by default). Runs on every
  /// launch; never unsubscribes.
  Future<void> enableNotificationsBasedOnPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool(kNotificationEnabled) ?? true)) {
      if (kDebugMode) {
        print('Global notifications are disabled. Skipping subscriptions.');
      }
      return;
    }
    for (final type in kNotificationTypes) {
      if (!(preferences.getBool(type.prefKey) ?? true)) continue;
      if (type.topic != null) {
        await subscribeToTopic(type.topic!);
      } else if (type.prefKey == kNotificationFollowedTitles) {
        await syncFollowedTitleTopics(true);
      }
    }
  }

  /// Seeds every notification preference to on, once per install, then
  /// subscribes accordingly.
  Future<void> initializeNotificationPreferencesOnce() async {
    final preferences = await SharedPreferences.getInstance();
    await enableNotificationsBasedOnPreferences();
    if (preferences.getBool(kNotificationsInitializedKey) == true) return;

    await preferences.setBool(kNotificationEnabled, true);
    for (final type in kNotificationTypes) {
      await preferences.setBool(type.prefKey, true);
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
