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

  // @override
  // Widget build(BuildContext context) {
  //   return MainLayout(
  //     title: 'Notifications',
  //     body: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //       child: Column(
  //         spacing: 10,
  //         children: [
  //           // Notifications Quote of the Day
  //           NotificationScreenLayout(
  //             iconData: Icons.format_quote_outlined,
  //             title: 'Quote of the Day',
  //             description: 'Manage all quote of the day',
  //             onTap: () => gotoAScreen(context, QuoteOfTheDayScreen.kRouteName),
  //           ),
  //           // Notifications Daily Inspiration
  //           NotificationScreenLayout(
  //             iconData: Icons.format_quote_outlined,
  //             title: 'Daily Inspiration',
  //             description: 'Manage all daily inspiration',
  //             onTap: () =>
  //                 gotoAScreen(context, DailyInspirationScreen.kRouteName),
  //           ),
  //           // Notifications Monday Motivation
  //           NotificationScreenLayout(
  //             iconData: Icons.format_quote_outlined,
  //             title: 'Monday Motivation',
  //             description: 'Manage all Monday Motivation',
  //             onTap: () =>
  //                 gotoAScreen(context, MotivationMondayScreen.kRouteName),
  //           ),
  //           SwitchSettingsLayout(
  //             title: 'Enable All Notifications',
  //             value: _notifications[kNotificationEnabled]!,
  //             onSwitchChanged: (value) => _onNotificationSwitched(
  //               kNotificationEnabled,
  //               kNotificationAllTopic,
  //               value,
  //             ),
  //           ),
  //           SwitchSettingsLayout(
  //             title: 'Enable Motivation Monday',
  //             value: _notifications[kNotificationMotivation]!,
  //             onSwitchChanged: (value) => _onNotificationSwitched(
  //               kNotificationMotivation,
  //               kNotificationMotivationMondayTopic,
  //               value,
  //             ),
  //           ),
  //           SwitchSettingsLayout(
  //             title: 'Enable Daily Inspiration',
  //             value: _notifications[kNotificationDailyInspiration]!,
  //             onSwitchChanged: (value) => _onNotificationSwitched(
  //               kNotificationDailyInspiration,
  //               kNotificationDailyInspirationTopic,
  //               value,
  //             ),
  //           ),
  //           SwitchSettingsLayout(
  //             title: 'Enable Quote of the Day',
  //             value: _notifications[kNotificationQuoteOfTheDay]!,
  //             onSwitchChanged: (value) => _onNotificationSwitched(
  //               kNotificationQuoteOfTheDay,
  //               kNotificationQuoteOfTheDayTopic,
  //               value,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Notifications',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Use a Column because the parent MainLayout provides the scrolling.
        child: Column(
          children: [
            // --- Section 1: Manage Notification Content ---
            _buildSectionHeader(context, "Manage Content"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              context: context,
              children: [
                NotificationScreenLayout(
                  iconData: Icons.tips_and_updates_outlined,
                  title: 'Quote of the Day',
                  description: 'Manage quote of the day alerts',
                  onTap: () =>
                      gotoAScreen(context, QuoteOfTheDayScreen.kRouteName),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                NotificationScreenLayout(
                  iconData: Icons.lightbulb_outline_rounded,
                  title: 'Daily Inspiration',
                  description: 'Manage daily inspiration alerts',
                  onTap: () =>
                      gotoAScreen(context, DailyInspirationScreen.kRouteName),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                NotificationScreenLayout(
                  iconData: Icons.calendar_month_outlined,
                  title: 'Monday Motivation',
                  description: 'Manage Monday Motivation alerts',
                  onTap: () =>
                      gotoAScreen(context, MotivationMondayScreen.kRouteName),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Section 2: General Notification Settings ---
            _buildSectionHeader(context, "General Settings"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              context: context,
              children: [
                SwitchSettingsLayout(
                  title: 'Enable All Notifications',
                  value: _notifications[kNotificationEnabled]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                    kNotificationEnabled,
                    kNotificationAllTopic,
                    value,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchSettingsLayout(
                  title: 'Enable Motivation Monday',
                  value: _notifications[kNotificationMotivation]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                    kNotificationMotivation,
                    kNotificationMotivationMondayTopic,
                    value,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchSettingsLayout(
                  title: 'Enable Daily Inspiration',
                  value: _notifications[kNotificationDailyInspiration]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                    kNotificationDailyInspiration,
                    kNotificationDailyInspirationTopic,
                    value,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
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
          ],
        ),
      ),
    );
  }

  // Helper widgets remain the same
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer(
      {required BuildContext context, required List<Widget> children}) {
    // This container creates the "card" effect for each group of settings
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      // ClipRRect ensures the children (like the ListTile ink splash) respect the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}
