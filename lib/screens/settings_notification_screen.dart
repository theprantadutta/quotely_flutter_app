import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/components/layouts/main_layout.dart';
import 'package:quotely_flutter_app/components/settings_screen/notifications/switch_settings_layout.dart';
import 'package:quotely_flutter_app/constants/notification_keys.dart';
import 'package:quotely_flutter_app/screens/daily_inspiration_screen.dart';
import 'package:quotely_flutter_app/screens/motivation_monday_screen.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/notifications_screen/notification_screen_layout.dart';
import '../constants/shared_preference_keys.dart';
import 'quote_of_the_day_screen.dart';

class SettingsNotificationScreen extends StatefulWidget {
  static const kRouteName = '/settings-notification';
  const SettingsNotificationScreen({super.key});

  @override
  State<SettingsNotificationScreen> createState() =>
      _SettingsNotificationState();
}

class _SettingsNotificationState extends State<SettingsNotificationScreen> {
  final Map<String, bool> _notifications = {
    kNotificationEnabled: true,
    kNotificationMotivation: true,
    kNotificationDailyInspiration: true,
    kNotificationQuoteOfTheDay: true,
  };

  SharedPreferences? _sharedPreferences;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _notifications.forEach((key, _) {
        _notifications[key] =
            _sharedPreferences?.getBool(key) ?? _notifications[key]!;
      });
    });
  }

  Future<void> _onNotificationSwitched(
    String key,
    String topic,
    bool value,
  ) async {
    final service = NotificationService();

    if (key == kNotificationEnabled) {
      setState(() {
        _notifications.forEach((notificationKey, _) {
          _notifications[notificationKey] = value;
        });
      });
      await _sharedPreferences?.setBool(kNotificationEnabled, value);

      if (value) {
        await service.subscribeToTopic(topic);
      } else {
        await service.unsubscribeFromAllTopic();
      }

      for (final notificationKey in _notifications.keys) {
        await _sharedPreferences?.setBool(notificationKey, value);
      }
    } else {
      setState(() {
        _notifications[key] = value;
      });
      await _sharedPreferences?.setBool(key, value);

      if (value) {
        await service.subscribeToTopic(topic);
      } else {
        await service.unsubscribeFromTopic(topic);
      }
    }
  }

  void gotoAScreen(BuildContext context, String route) {
    try {
      Future.delayed(Duration.zero, () async {
        // ignore: use_build_context_synchronously
        context.push(route);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Something Went Wrong when going to screen: $route');
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Notifications',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          spacing: 10,
          children: [
            // Notifications Quote of the Day
            NotificationScreenLayout(
              iconData: Icons.format_quote_outlined,
              title: 'Quote of the Day',
              description: 'Manage all quote of the day',
              onTap: () => gotoAScreen(context, QuoteOfTheDayScreen.kRouteName),
            ),
            // Notifications Daily Inspiration
            NotificationScreenLayout(
              iconData: Icons.format_quote_outlined,
              title: 'Daily Inspiration',
              description: 'Manage all daily inspiration',
              onTap: () =>
                  gotoAScreen(context, DailyInspirationScreen.kRouteName),
            ),
            // Notifications Monday Motivation
            NotificationScreenLayout(
              iconData: Icons.format_quote_outlined,
              title: 'Monday Motivation',
              description: 'Manage all Monday Motivation',
              onTap: () =>
                  gotoAScreen(context, MotivationMondayScreen.kRouteName),
            ),
            SwitchSettingsLayout(
              title: 'Enable All Notifications',
              value: _notifications[kNotificationEnabled]!,
              onSwitchChanged: (value) => _onNotificationSwitched(
                kNotificationEnabled,
                kNotificationAllTopic,
                value,
              ),
            ),
            SwitchSettingsLayout(
              title: 'Enable Motivation Monday',
              value: _notifications[kNotificationMotivation]!,
              onSwitchChanged: (value) => _onNotificationSwitched(
                kNotificationMotivation,
                kNotificationMotivationMondayTopic,
                value,
              ),
            ),
            SwitchSettingsLayout(
              title: 'Enable Daily Inspiration',
              value: _notifications[kNotificationDailyInspiration]!,
              onSwitchChanged: (value) => _onNotificationSwitched(
                kNotificationDailyInspiration,
                kNotificationDailyInspirationTopic,
                value,
              ),
            ),
            SwitchSettingsLayout(
              title: 'Enable Quote of the Day',
              value: _notifications[kNotificationQuoteOfTheDay]!,
              onSwitchChanged: (value) => _onNotificationSwitched(
                kNotificationQuoteOfTheDay,
                kNotificationQuoteOfTheDayTopic,
                value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
