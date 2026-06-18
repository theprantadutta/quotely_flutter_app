import 'notification_keys.dart';
import 'shared_preference_keys.dart';

/// Which content family a notification belongs to — used to group the toggles
/// into "Quotes" and "Facts" sections.
enum NotificationGroup { quote, fact }

/// One toggleable notification kind. Ties together the user-facing label, the
/// SharedPreferences key it persists under, and the FCM topic it (un)subscribes
/// from. This is the single source of truth shared by the notifications
/// onboarding screen and the Settings → Notifications screen.
class NotificationType {
  final String title;
  final String description;
  final String prefKey;
  final String topic;
  final NotificationGroup group;

  const NotificationType({
    required this.title,
    required this.description,
    required this.prefKey,
    required this.topic,
    required this.group,
  });
}

/// All toggleable notification kinds, in display order within their group.
const List<NotificationType> kNotificationTypes = [
  // --- Quotes ---
  NotificationType(
    title: 'Quote of the Day',
    description: 'A hand-picked quote, every day.',
    prefKey: kNotificationQuoteOfTheDay,
    topic: kNotificationQuoteOfTheDayTopic,
    group: NotificationGroup.quote,
  ),
  NotificationType(
    title: 'Daily Inspiration',
    description: 'A daily dose of motivation to keep you going.',
    prefKey: kNotificationDailyInspiration,
    topic: kNotificationDailyInspirationTopic,
    group: NotificationGroup.quote,
  ),
  NotificationType(
    title: 'Motivation Monday',
    description: 'Start your week with a motivational boost.',
    prefKey: kNotificationMotivation,
    topic: kNotificationMotivationMondayTopic,
    group: NotificationGroup.quote,
  ),

  // --- Facts ---
  NotificationType(
    title: 'Fact of the Day',
    description: 'Learn something new every single day.',
    prefKey: kNotificationFactOfTheDay,
    topic: kNotificationFactOfTheDayTopic,
    group: NotificationGroup.fact,
  ),
  NotificationType(
    title: 'Daily Brain Food',
    description: 'A daily fact to feed your curiosity.',
    prefKey: kNotificationDailyBrainFood,
    topic: kNotificationDailyBrainFoodTopic,
    group: NotificationGroup.fact,
  ),
  NotificationType(
    title: 'Weird Fact Wednesday',
    description: 'A delightfully strange fact mid-week.',
    prefKey: kNotificationWeirdFactWednesday,
    topic: kNotificationWeirdFactWednesdayTopic,
    group: NotificationGroup.fact,
  ),
];

/// The notification kinds in a given [group], preserving declared order.
List<NotificationType> notificationTypesIn(NotificationGroup group) =>
    kNotificationTypes.where((t) => t.group == group).toList();
