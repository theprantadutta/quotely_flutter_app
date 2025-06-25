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

    // Fact Notifications
    kNotificationFactOfTheDay: true,
    kNotificationDailyBrainFood: true,
    kNotificationWeirdFactWednesday: true,
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
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         children: [
  //           // --- Section 1: Manage Notification Content ---
  //           _buildSectionHeader(context, "Manage Content"),
  //           const SizedBox(height: 8),
  //           _buildSectionContainer(
  //             context: context,
  //             children: [
  //               NotificationScreenLayout(
  //                 iconData: Icons.tips_and_updates_outlined,
  //                 title: 'Quote of the Day',
  //                 description: 'Manage quote of the day alerts',
  //                 onTap: () =>
  //                     gotoAScreen(context, QuoteOfTheDayScreen.kRouteName),
  //               ),
  //               const Divider(height: 1, indent: 16, endIndent: 16),
  //               NotificationScreenLayout(
  //                 iconData: Icons.lightbulb_outline_rounded,
  //                 title: 'Daily Inspiration',
  //                 description: 'Manage daily inspiration alerts',
  //                 onTap: () =>
  //                     gotoAScreen(context, DailyInspirationScreen.kRouteName),
  //               ),
  //               const Divider(height: 1, indent: 16, endIndent: 16),
  //               NotificationScreenLayout(
  //                 iconData: Icons.calendar_month_outlined,
  //                 title: 'Monday Motivation',
  //                 description: 'Manage Monday Motivation alerts',
  //                 onTap: () =>
  //                     gotoAScreen(context, MotivationMondayScreen.kRouteName),
  //               ),
  //             ],
  //           ),

  //           const SizedBox(height: 24),

  //           _buildSectionHeader(context, "Fact Notifications"),
  //           const SizedBox(height: 8),
  //           _buildSectionContainer(
  //             context: context,
  //             children: [
  //               SwitchSettingsLayout(
  //                 title: 'Enable Fact of the Day',
  //                 value: _notifications[kNotificationFactOfTheDay]!,
  //                 onSwitchChanged: (value) => _onNotificationSwitched(
  //                   kNotificationFactOfTheDay,
  //                   kFactOfTheDayTopic,
  //                   value,
  //                 ),
  //               ),
  //               const Divider(height: 1, indent: 16, endIndent: 16),
  //               SwitchSettingsLayout(
  //                 title: 'Enable Daily Brain Food',
  //                 value: _notifications[kNotificationDailyBrainFood]!,
  //                 onSwitchChanged: (value) => _onNotificationSwitched(
  //                   kNotificationDailyBrainFood,
  //                   kDailyBrainFoodTopic,
  //                   value,
  //                 ),
  //               ),
  //               const Divider(height: 1, indent: 16, endIndent: 16),
  //               SwitchSettingsLayout(
  //                 title: 'Enable Weird Fact Wednesday',
  //                 value: _notifications[kNotificationWeirdFactWednesday]!,
  //                 onSwitchChanged: (value) => _onNotificationSwitched(
  //                   kNotificationWeirdFactWednesday,
  //                   kWeirdFactWednesdayTopic,
  //                   value,
  //                 ),
  //               ),
  //             ],
  //           ),

  //           const SizedBox(height: 24),

  //           // --- Section 2: General Notification Settings ---
  //           _buildSectionHeader(context, "General Settings"),
  //           const SizedBox(height: 8),
  //           _buildSectionContainer(
  //             context: context,
  //             children: [
  //               SwitchSettingsLayout(
  //                 title: 'Enable All Notifications',
  //                 value: _notifications[kNotificationEnabled]!,
  //                 onSwitchChanged: (value) => _onNotificationSwitched(
  //                   kNotificationEnabled,
  //                   kNotificationAllTopic,
  //                   value,
  //                 ),
  //               ),
  //               const Divider(height: 1, indent: 16, endIndent: 16),
  //               SwitchSettingsLayout(
  //                 title: 'Enable Motivation Monday',
  //                 value: _notifications[kNotificationMotivation]!,
  //                 onSwitchChanged: (value) => _onNotificationSwitched(
  //                   kNotificationMotivation,
  //                   kNotificationMotivationMondayTopic,
  //                   value,
  //                 ),
  //               ),
  //               const Divider(height: 1, indent: 16, endIndent: 16),
  //               SwitchSettingsLayout(
  //                 title: 'Enable Daily Inspiration',
  //                 value: _notifications[kNotificationDailyInspiration]!,
  //                 onSwitchChanged: (value) => _onNotificationSwitched(
  //                   kNotificationDailyInspiration,
  //                   kNotificationDailyInspirationTopic,
  //                   value,
  //                 ),
  //               ),
  //               const Divider(height: 1, indent: 16, endIndent: 16),
  //               SwitchSettingsLayout(
  //                 title: 'Enable Quote of the Day',
  //                 value: _notifications[kNotificationQuoteOfTheDay]!,
  //                 onSwitchChanged: (value) => _onNotificationSwitched(
  //                   kNotificationQuoteOfTheDay,
  //                   kNotificationQuoteOfTheDayTopic,
  //                   value,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // // Helper widgets remain the same
  // Widget _buildSectionHeader(BuildContext context, String title) {
  //   return Align(
  //     alignment: Alignment.centerLeft,
  //     child: Padding(
  //       padding: const EdgeInsets.only(left: 4.0, bottom: 8),
  //       child: Text(
  //         title.toUpperCase(),
  //         style: Theme.of(context).textTheme.labelLarge?.copyWith(
  //               fontWeight: FontWeight.bold,
  //               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
  //             ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildSectionContainer(
  //     {required BuildContext context, required List<Widget> children}) {
  //   // This container creates the "card" effect for each group of settings
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surfaceContainer,
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     // ClipRRect ensures the children (like the ListTile ink splash) respect the rounded corners
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(16),
  //       child: Column(children: children),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Notifications',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // --- 1. The Standalone Master Switch ---
            _buildMasterSwitchContainer(
              child: SwitchListTile(
                title: const Text('Enable All Notifications',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(
                  'This is the main switch for all alerts from Quotely.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                value: _notifications[kNotificationEnabled]!,
                onChanged: (value) => _onNotificationSwitched(
                    kNotificationEnabled, kNotificationAllTopic, value),
                contentPadding: const EdgeInsets.only(
                    left: 16, right: 8, top: 8, bottom: 8),
              ),
            ),

            const SizedBox(height: 32),

            // --- 3. Quote Notification Toggles ---
            _buildSectionHeader(context, "Quote Notification Toggles"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              children: [
                SwitchSettingsLayout(
                  title: 'Quote of the Day',
                  value: _notifications[kNotificationQuoteOfTheDay]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                      kNotificationQuoteOfTheDay,
                      kNotificationQuoteOfTheDayTopic,
                      value),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchSettingsLayout(
                  title: 'Daily Inspiration',
                  value: _notifications[kNotificationDailyInspiration]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                      kNotificationDailyInspiration,
                      kNotificationDailyInspirationTopic,
                      value),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchSettingsLayout(
                  title: 'Motivation Monday',
                  value: _notifications[kNotificationMotivation]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                      kNotificationMotivation,
                      kNotificationMotivationMondayTopic,
                      value),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- 4. Fact Notification Toggles ---
            _buildSectionHeader(context, "Fact Notification Toggles"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              children: [
                SwitchSettingsLayout(
                  title: 'Fact of the Day',
                  value: _notifications[kNotificationFactOfTheDay]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                      kNotificationFactOfTheDay, kFactOfTheDayTopic, value),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchSettingsLayout(
                  title: 'Daily Brain Food',
                  value: _notifications[kNotificationDailyBrainFood]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                      kNotificationDailyBrainFood, kDailyBrainFoodTopic, value),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                SwitchSettingsLayout(
                  title: 'Weird Fact Wednesday',
                  value: _notifications[kNotificationWeirdFactWednesday]!,
                  onSwitchChanged: (value) => _onNotificationSwitched(
                      kNotificationWeirdFactWednesday,
                      kWeirdFactWednesdayTopic,
                      value),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- 2. Manage Content (Quotes & Facts Navigation) ---
            _buildSectionHeader(context, "Manage Notification Content"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              children: [
                NotificationScreenLayout(
                  iconData: Icons.tips_and_updates_outlined,
                  title: 'Quote of the Day',
                  description: 'View the featured daily quote',
                  onTap: () =>
                      gotoAScreen(context, QuoteOfTheDayScreen.kRouteName),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                NotificationScreenLayout(
                  iconData: Icons.lightbulb_outline_rounded,
                  title: 'Daily Inspiration',
                  description: 'Catch up on inspiration alerts',
                  onTap: () =>
                      gotoAScreen(context, DailyInspirationScreen.kRouteName),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                NotificationScreenLayout(
                  iconData: Icons.calendar_month_outlined,
                  title: 'Monday Motivation',
                  description: 'Review past motivation alerts',
                  onTap: () =>
                      gotoAScreen(context, MotivationMondayScreen.kRouteName),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                NotificationScreenLayout(
                  iconData: Icons.fact_check_outlined,
                  title: 'Fact of the Day',
                  description: 'View the featured daily fact',
                  onTap: () {}, // TODO: Add navigation
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                NotificationScreenLayout(
                  iconData: Icons.psychology_outlined,
                  title: 'Daily Brain Food',
                  description: 'Catch up on interesting tidbits',
                  onTap: () {}, // TODO: Add navigation
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                NotificationScreenLayout(
                  iconData: Icons.interests_outlined,
                  title: 'Weird Fact Wednesday',
                  description: 'Review past weird facts',
                  onTap: () {}, // TODO: Add navigation
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Helper widgets for the new design
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 1.2,
          ),
    );
  }

  Widget _buildMasterSwitchContainer({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}
