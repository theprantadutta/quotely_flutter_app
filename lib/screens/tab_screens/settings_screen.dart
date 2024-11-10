import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/settings_screen/settings_screen_layout.dart';
import 'package:quotely_flutter_app/components/shared/top_navigation_bar.dart';

class SettingsScreen extends StatelessWidget {
  static const kRouteName = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        children: [
          TopNavigationBar(title: 'Settings'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  // Settings Appearance
                  SettingsScreenLayout(
                    iconData: Icons.contrast_outlined,
                    title: 'Appearance',
                    description: 'Control How your app looks',
                  ),
                  // Settings Quote of the Day
                  SettingsScreenLayout(
                    iconData: Icons.format_quote_outlined,
                    title: 'Quote of the Day',
                    description: 'Manage all quote of the day',
                  ),
                  // Settings Notifications
                  SettingsScreenLayout(
                    iconData: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    description: 'Manage Notifications',
                  ),
                  // Settings Offline Support
                  SettingsScreenLayout(
                    iconData: Icons.wifi_off_outlined,
                    title: 'Offline Support',
                    description: 'Use the app even when online',
                  ),
                  // Settings About Quotely App
                  SettingsScreenLayout(
                    iconData: Icons.help_outlined,
                    title: 'About Quotely',
                    description: 'About Quotely app',
                  ),
                  // Settings Reset Everything to default
                  SettingsScreenLayout(
                    iconData: Icons.notifications_active_outlined,
                    title: 'Reset Settings',
                    description: 'Reset All Settings to Default',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
