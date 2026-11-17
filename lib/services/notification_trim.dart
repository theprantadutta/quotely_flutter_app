import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/notification_keys.dart';
import '../constants/notification_types.dart';
import '../constants/shared_preference_keys.dart';
import 'install_cohort.dart';
import 'notification_service.dart';

/// The answers to "Too many notifications?".
enum NotificationTrimAnswer {
  keepOne('keep_one'),
  choose('choose'),
  keepAll('keep_all'),

  /// Swiped away: nothing changes.
  dismissed('dismissed');

  /// The analytics parameter value.
  final String wire;
  const NotificationTrimAnswer(this.wire);
}

/// A one-time offer to installs from before 3.2.0, which kept every
/// notification kind on, to cut down to Quote of the day.
abstract final class NotificationTrim {
  /// How many notification kinds are on.
  static int enabledCount(SharedPreferences prefs) => kNotificationTypes
      .where((t) => NotificationService.isEnabled(prefs, t.prefKey))
      .length;

  /// Not offered yet, an install that ran a version before 3.4.0 and still
  /// has the old all-on defaults (3.2.0 and 3.3.x installs started calm and
  /// picked what they have), notifications on, and more than two kinds on.
  static bool shouldOffer(SharedPreferences prefs) =>
      !(prefs.getBool(kNotificationTrimShownKey) ?? false) &&
      InstallCohort.isExisting(prefs) &&
      !NotificationService.usesCalmDefaults(prefs) &&
      (prefs.getBool(kHasSeenNotificationPrompt) ?? false) &&
      NotificationService.isEnabled(prefs, kNotificationEnabled) &&
      enabledCount(prefs) > 2;

  /// Remembered as soon as it is shown, whatever the answer.
  static Future<void> markShown(SharedPreferences prefs) =>
      prefs.setBool(kNotificationTrimShownKey, true);

  /// [NotificationTrimAnswer.keepOne]: Quote of the day stays, every other
  /// kind goes off, in prefs (what Settings → Notifications shows) and in
  /// FCM. Prefs first: they apply offline. FCM queues topic changes made
  /// offline; if one fails anyway, the kind is off in Settings and can be
  /// toggled again there.
  static Future<void> keepJustQuoteOfTheDay(
    SharedPreferences prefs,
    NotificationService service,
  ) async {
    for (final type in kNotificationTypes) {
      await prefs.setBool(
        type.prefKey,
        type.prefKey == kNotificationQuoteOfTheDay,
      );
    }
    await prefs.setBool(kNotificationEnabled, true);
    try {
      for (final type in kNotificationTypes) {
        final topic = type.topic;
        if (topic == null) {
          if (type.prefKey == kNotificationFollowedTitles) {
            await service.syncFollowedTitleTopics(false);
          }
        } else if (type.prefKey == kNotificationQuoteOfTheDay) {
          await service.subscribeToTopic(topic);
        } else {
          await service.unsubscribeFromTopic(topic);
        }
      }
      // Announcements to everyone stay on, as they do for new installs.
      await service.subscribeToTopic(kNotificationAllTopic);
    } catch (e) {
      debugPrint('Notification trim: topics not all updated: $e');
    }
  }
}
