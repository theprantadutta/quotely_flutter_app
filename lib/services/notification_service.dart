import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quotely_flutter_app/constants/notification_keys.dart';

class NotificationService {
  Future<void> subscribeToTopic(String topic) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.unsubscribeFromTopic(topic);
  }

  Future<void> subscribeToAllTopic() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.subscribeToTopic(kNotificationAllTopic);
    await messaging.subscribeToTopic(kNotificationDailyInspirationTopic);
    await messaging.subscribeToTopic(kNotificationMotivationMondayTopic);
    await messaging.subscribeToTopic(kNotificationQuoteOfTheDayTopic);
  }

  Future<void> unsubscribeFromAllTopic() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.unsubscribeFromTopic(kNotificationAllTopic);
    await messaging.unsubscribeFromTopic(kNotificationDailyInspirationTopic);
    await messaging.unsubscribeFromTopic(kNotificationMotivationMondayTopic);
    await messaging.unsubscribeFromTopic(kNotificationQuoteOfTheDayTopic);
  }
}
