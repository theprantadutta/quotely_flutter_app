import 'notification_keys.dart';
import 'shared_preference_keys.dart';

/// Which content family a notification belongs to; groups the toggles into
/// the QUOTES / SCENES / FACTS sections.
enum NotificationGroup { quote, scene, fact }

extension NotificationGroupLabel on NotificationGroup {
  String get label => switch (this) {
    NotificationGroup.quote => 'Quotes',
    NotificationGroup.scene => 'Scenes',
    NotificationGroup.fact => 'Facts',
  };
}

/// One toggleable notification kind: label, schedule copy, pref key and FCM
/// topic. Single source of truth for the primer and Settings → Notifications.
class NotificationType {
  final String title;

  /// Settings copy ("8:00 AM", "Mondays 9:00 AM").
  final String schedule;

  /// Primer copy ("Every morning at 8:00").
  final String primerDescription;
  final String prefKey;

  /// FCM topic. Null for [kNotificationFollowedTitles], which fans out to one
  /// `title_<slug>` topic per followed title.
  final String? topic;
  final NotificationGroup group;
  final bool isNew;

  /// Shown on the onboarding primer (the per-title one needs titles first).
  final bool inPrimer;

  const NotificationType({
    required this.title,
    required this.schedule,
    required this.primerDescription,
    required this.prefKey,
    required this.topic,
    required this.group,
    this.isNew = false,
    this.inPrimer = true,
  });
}

/// All toggleable notification kinds, in display order within their group.
const List<NotificationType> kNotificationTypes = [
  // --- Quotes ---
  NotificationType(
    title: 'Quote of the day',
    schedule: '8:00 AM',
    primerDescription: 'Every morning at 8:00',
    prefKey: kNotificationQuoteOfTheDay,
    topic: kNotificationQuoteOfTheDayTopic,
    group: NotificationGroup.quote,
  ),
  NotificationType(
    title: 'Daily inspiration',
    schedule: '2× a day',
    primerDescription: 'Twice a day, random times',
    prefKey: kNotificationDailyInspiration,
    topic: kNotificationDailyInspirationTopic,
    group: NotificationGroup.quote,
  ),
  NotificationType(
    title: 'Monday motivation',
    schedule: 'Mondays 9:00 AM',
    primerDescription: 'Mondays at 9:00',
    prefKey: kNotificationMotivation,
    topic: kNotificationMotivationMondayTopic,
    group: NotificationGroup.quote,
  ),

  // --- Scenes ---
  NotificationType(
    title: 'Friday night lines',
    schedule: 'Fridays 7:00 PM',
    primerDescription: 'A film or TV line, Fridays 7 PM',
    prefKey: kNotificationFridayNightLines,
    topic: kNotificationFridayNightLinesTopic,
    group: NotificationGroup.scene,
    isNew: true,
  ),
  NotificationType(
    title: 'New from titles you follow',
    schedule: 'When lines are added',
    primerDescription: 'When lines are added',
    prefKey: kNotificationFollowedTitles,
    topic: null,
    group: NotificationGroup.scene,
    isNew: true,
    inPrimer: false,
  ),

  // --- Facts ---
  NotificationType(
    title: 'Fact of the day',
    schedule: '12:00 PM',
    primerDescription: 'Something new at lunchtime',
    prefKey: kNotificationFactOfTheDay,
    topic: kNotificationFactOfTheDayTopic,
    group: NotificationGroup.fact,
  ),
  NotificationType(
    title: 'Daily brain food',
    schedule: '6:00 PM',
    primerDescription: 'An evening fact to chew on',
    prefKey: kNotificationDailyBrainFood,
    topic: kNotificationDailyBrainFoodTopic,
    group: NotificationGroup.fact,
  ),
  NotificationType(
    title: 'Weird fact Wednesday',
    schedule: 'Wednesdays',
    primerDescription: 'A strange one, mid-week',
    prefKey: kNotificationWeirdFactWednesday,
    topic: kNotificationWeirdFactWednesdayTopic,
    group: NotificationGroup.fact,
  ),
];

/// The notification kinds in a given [group], preserving declared order.
List<NotificationType> notificationTypesIn(NotificationGroup group) =>
    kNotificationTypes.where((t) => t.group == group).toList();
