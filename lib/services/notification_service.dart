import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/constants/notification_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';

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
    // Subscribe to Quote Topics
    await messaging.subscribeToTopic(kNotificationAllTopic);
    await messaging.subscribeToTopic(kNotificationDailyInspirationTopic);
    await messaging.subscribeToTopic(kNotificationMotivationMondayTopic);
    await messaging.subscribeToTopic(kNotificationQuoteOfTheDayTopic);
    // --- ADDED: Subscribe to new Fact Topics ---
    await messaging.subscribeToTopic(kNotificationFactOfTheDayTopic);
    await messaging.subscribeToTopic(kNotificationDailyBrainFoodTopic);
    await messaging.subscribeToTopic(kNotificationWeirdFactWednesdayTopic);
  }

  Future<void> unsubscribeFromAllTopic() async {
    final messaging = FirebaseMessaging.instance;
    // Unsubscribe from Quote Topics
    await messaging.unsubscribeFromTopic(kNotificationAllTopic);
    await messaging.unsubscribeFromTopic(kNotificationDailyInspirationTopic);
    await messaging.unsubscribeFromTopic(kNotificationMotivationMondayTopic);
    await messaging.unsubscribeFromTopic(kNotificationQuoteOfTheDayTopic);
    // --- ADDED: Unsubscribe from new Fact Topics ---
    await messaging.unsubscribeFromTopic(kNotificationFactOfTheDayTopic);
    await messaging.unsubscribeFromTopic(kNotificationDailyBrainFoodTopic);
    await messaging.unsubscribeFromTopic(kNotificationWeirdFactWednesdayTopic);
  }

  /// Subscribes to specific notification topics based on user preferences stored in SharedPreferences.
  /// It only subscribes if the preference is explicitly set to true.
  /// If the preference is false or not set, it skips subscription for that topic.
  Future<void> enableNotificationsBasedOnPreferences() async {
    final preferences = await SharedPreferences.getInstance();

    // Define a map of preference keys to their corresponding Firebase topic keys
    final Map<String, String> notificationMap = {
      // Quote Notifications
      kNotificationQuoteOfTheDay: kNotificationQuoteOfTheDayTopic,
      kNotificationDailyInspiration: kNotificationDailyInspirationTopic,
      kNotificationMotivation: kNotificationMotivationMondayTopic,

      // Fact Notifications
      kNotificationFactOfTheDay: kNotificationFactOfTheDayTopic,
      kNotificationDailyBrainFood: kNotificationDailyBrainFoodTopic,
      kNotificationWeirdFactWednesday: kNotificationWeirdFactWednesdayTopic,
    };

    // First, handle the master switch: kNotificationEnabled
    // If kNotificationEnabled is false, we should not subscribe to anything.
    // If it's true (or not set, defaulting to true), then proceed to individual topics.
    final bool areNotificationsGloballyEnabled =
        preferences.getBool(kNotificationEnabled) ?? true;

    if (areNotificationsGloballyEnabled) {
      // Loop through each specific notification type
      for (var entry in notificationMap.entries) {
        final String prefKey = entry.key;
        final String topicKey = entry.value;

        // Check if the individual notification preference is true
        // Default to true if the preference key is not found,
        // so new notification types are opt-in by default
        final bool isNotificationTypeEnabled =
            preferences.getBool(prefKey) ?? true;

        if (isNotificationTypeEnabled) {
          await subscribeToTopic(topicKey);
        }
        // If isNotificationTypeEnabled is false, we do nothing (skip subscription),
        // as per your requirement. No unsubscription here.
      }
      // Consider if 'kNotificationAllTopic' should always be subscribed if global is true,
      // or if it's managed by subscribeToAllTopic/unsubscribeFromAllTopic in the UI logic.
      // For this function, we focus on the individual granular topics.
    } else {
      // If global notifications are disabled, we might want to ensure ALL are unsubscribed
      // This part is handled by your _onNotificationSwitched when kNotificationEnabled is toggled.
      // So, this function doesn't need to unsubscribe when global is off, as it's meant
      // to *enable* based on preferences.
      if (kDebugMode) {
        print(
            'Global notifications are disabled. Skipping specific topic subscriptions.');
      }
    }
  }

  /// Initializes all notification preferences in SharedPreferences to true,
  /// but only if they haven't been initialized before.
  /// This function is designed to run only once, typically on first app launch.
  Future<void> initializeNotificationPreferencesOnce() async {
    final preferences = await SharedPreferences.getInstance();

    // Key to check if initialization has already occurred
    const String kNotificationsInitializedKey =
        'notifications_preferences_initialized';

    // run the subscribe function
    await enableNotificationsBasedOnPreferences();

    // Check if preferences have already been set
    if (preferences.getBool(kNotificationsInitializedKey) == true) {
      if (kDebugMode) {
        print('Notification preferences already initialized. Skipping.');
      }
      return; // Exit if already initialized
    }

    // List of all notification preference keys to set to true
    final List<String> allNotificationPrefKeys = [
      kNotificationEnabled,
      kNotificationMotivation,
      kNotificationDailyInspiration,
      kNotificationQuoteOfTheDay,
      kNotificationFactOfTheDay,
      kNotificationDailyBrainFood,
      kNotificationWeirdFactWednesday,
    ];

    // Set all relevant notification preferences to true
    for (final String key in allNotificationPrefKeys) {
      await preferences.setBool(key, true);
      if (kDebugMode) {
        print('Set $key to true in SharedPreferences.');
      } // For debugging
    }

    // Mark the initialization as complete
    await preferences.setBool(kNotificationsInitializedKey, true);
    if (kDebugMode) {
      print('Notification preferences initialization complete.');
    }

    // After setting preferences, immediately subscribe based on these newly set preferences.
    // This ensures that on the very first launch, users are subscribed to all default topics.
    await enableNotificationsBasedOnPreferences();
  }
}
