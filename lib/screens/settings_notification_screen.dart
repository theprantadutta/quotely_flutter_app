import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/layouts/main_layout.dart';
import 'package:quotely_flutter_app/components/settings_screen/notifications/switch_settings_layout.dart';
import 'package:quotely_flutter_app/constants/notification_keys.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';

// class SettingsNotificationScreen extends StatefulWidget {
//   static const kRouteName = '/settings-notification';
//   const SettingsNotificationScreen({super.key});

//   @override
//   State<SettingsNotificationScreen> createState() =>
//       _SettingsNotificationState();
// }

// class _SettingsNotificationState extends State<SettingsNotificationScreen> {
//   bool _isNotificationEnabled = true;
//   bool _isNotificationMotivationEnabled = false;
//   bool _isNotificationDailyInspirationEnabled = false;
//   bool _isNotificationQuoteOfTheDayEnabled = false;
//   SharedPreferences? _sharedPreferences;

//   @override
//   void initState() {
//     super.initState();
//     initializeSharedPreference();
//   }

//   Future<void> initializeSharedPreference() async {
//     _sharedPreferences = await SharedPreferences.getInstance();
//     final isNotificationEnabled =
//         _sharedPreferences?.getBool(kNotificationEnabled);
//     if (isNotificationEnabled != null) {
//       setState(() => _isNotificationEnabled = isNotificationEnabled);
//     }
//     final isNotificationMotivationEnabled =
//         _sharedPreferences?.getBool(kNotificationMotivation);
//     if (isNotificationMotivationEnabled != null) {
//       setState(() =>
//           _isNotificationMotivationEnabled = isNotificationMotivationEnabled);
//     }
//     final isNotificationDailyInspirationEnabled =
//         _sharedPreferences?.getBool(kNotificationDailyInspiration);
//     if (isNotificationDailyInspirationEnabled != null) {
//       setState(() => _isNotificationDailyInspirationEnabled =
//           isNotificationDailyInspirationEnabled);
//     }
//     final isNotificationQuoteOfTheWeekEnabled =
//         _sharedPreferences?.getBool(kNotificationQuoteOfTheDay);
//     if (isNotificationQuoteOfTheWeekEnabled != null) {
//       setState(() => _isNotificationQuoteOfTheDayEnabled =
//           isNotificationQuoteOfTheWeekEnabled);
//     }
//   }

//   Future<void> onNotificationSwitched(bool isNotificationEnabled) async {
//     setState(() {
//       _isNotificationEnabled = isNotificationEnabled;
//       _sharedPreferences?.setBool(kNotificationEnabled, isNotificationEnabled);
//     });
//     if (isNotificationEnabled) {
//       await NotificationService().subscribeToTopic(kNotificationAllTopic);
//     } else {
//       await NotificationService().unsubscribeFromAllTopic();
//     }
//   }

//   Future<void> onNotificationMondayMotivationSwitched(
//       bool isNotificationMotivationEnabled) async {
//     setState(() {
//       _isNotificationMotivationEnabled = isNotificationMotivationEnabled;
//       _sharedPreferences?.setBool(
//           kNotificationMotivation, isNotificationMotivationEnabled);
//     });
//     if (isNotificationMotivationEnabled) {
//       await NotificationService()
//           .subscribeToTopic(kNotificationMotivationMondayTopic);
//     } else {
//       await NotificationService()
//           .unsubscribeFromTopic(kNotificationMotivationMondayTopic);
//     }
//   }

//   Future<void> onNotificationDailyInspirationSwitched(
//       bool isNotificationDailyInspirationEnabled) async {
//     setState(() {
//       _isNotificationMotivationEnabled = isNotificationDailyInspirationEnabled;
//       _sharedPreferences?.setBool(
//           kNotificationDailyInspiration, isNotificationDailyInspirationEnabled);
//     });
//     if (isNotificationDailyInspirationEnabled) {
//       await NotificationService()
//           .subscribeToTopic(kNotificationDailyInspirationTopic);
//     } else {
//       await NotificationService()
//           .unsubscribeFromTopic(kNotificationDailyInspirationTopic);
//     }
//   }

//   Future<void> onNotificationQuoteOfTheWeekSwitched(
//       bool isNotificationQuoteOfTheWeekEnabled) async {
//     setState(() {
//       _isNotificationQuoteOfTheDayEnabled = isNotificationQuoteOfTheWeekEnabled;
//       _sharedPreferences?.setBool(
//           kNotificationQuoteOfTheDay, isNotificationQuoteOfTheWeekEnabled);
//     });
//     if (isNotificationQuoteOfTheWeekEnabled) {
//       await NotificationService()
//           .subscribeToTopic(kNotificationQuoteOfTheDayTopic);
//     } else {
//       await NotificationService()
//           .unsubscribeFromTopic(kNotificationQuoteOfTheDayTopic);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MainLayout(
//       title: 'Notifications',
//       body: Padding(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 10,
//           vertical: 8,
//         ),
//         child: Column(
//           children: [
//             SwitchSettingsLayout(
//               title: 'Enable All Notifications',
//               value: _isNotificationEnabled,
//               onSwitchChanged: onNotificationSwitched,
//             ),
//             SizedBox(height: 6),
//             SwitchSettingsLayout(
//               title: 'Enable Motivation Monday',
//               value: _isNotificationMotivationEnabled,
//               onSwitchChanged: onNotificationMondayMotivationSwitched,
//             ),
//             SizedBox(height: 6),
//             SwitchSettingsLayout(
//               title: 'Enable Daily Inspiration',
//               value: _isNotificationDailyInspirationEnabled,
//               onSwitchChanged: onNotificationDailyInspirationSwitched,
//             ),
//             SizedBox(height: 6),
//             SwitchSettingsLayout(
//               title: 'Enable Quote of the Day',
//               value: _isNotificationQuoteOfTheDayEnabled,
//               onSwitchChanged: onNotificationMondayMotivationSwitched,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Notifications',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
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
            const SizedBox(height: 6),
            SwitchSettingsLayout(
              title: 'Enable Motivation Monday',
              value: _notifications[kNotificationMotivation]!,
              onSwitchChanged: (value) => _onNotificationSwitched(
                kNotificationMotivation,
                kNotificationMotivationMondayTopic,
                value,
              ),
            ),
            const SizedBox(height: 6),
            SwitchSettingsLayout(
              title: 'Enable Daily Inspiration',
              value: _notifications[kNotificationDailyInspiration]!,
              onSwitchChanged: (value) => _onNotificationSwitched(
                kNotificationDailyInspiration,
                kNotificationDailyInspirationTopic,
                value,
              ),
            ),
            const SizedBox(height: 6),
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
