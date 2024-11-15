import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../components/settings_screen/appearance/appearance_screen.dart';
import '../../../components/settings_screen/settings_screen_layout.dart';
import '../../../components/shared/top_navigation_bar.dart';
import '../../../screens/quote_of_the_day_screen.dart';
import '../../../screens/settings_notification_screen.dart';
import '../../../screens/settings_offline_support_screen.dart';
import '../../services/common_service.dart';

class SettingsScreen extends StatelessWidget {
  static const kRouteName = '/settings';
  const SettingsScreen({super.key});

  Future<void> showAboutSection(BuildContext context) async {
    final platform = await PackageInfo.fromPlatform();
    final version = platform.version;
    showAboutDialog(
      // ignore: use_build_context_synchronously
      context: context,
      applicationVersion: version,
      applicationName: 'Quotely',
      children: [
        const Column(
          children: [
            Text(
              'Developed & Maintained By',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              'PRANTA Dutta',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const TopNavigationBar(title: 'Settings'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  // Settings Appearance
                  SettingsScreenLayout(
                    iconData: Icons.contrast_outlined,
                    title: 'Appearance',
                    description: 'Control How your app looks',
                    onTap: () => context.push(AppearanceScreen.kRouteName),
                  ),
                  // Settings Quote of the Day
                  SettingsScreenLayout(
                    iconData: Icons.format_quote_outlined,
                    title: 'Quote of the Day',
                    description: 'Manage all quote of the day',
                    onTap: () => context.push(QuoteOfTheDayScreen.kRouteName),
                  ),
                  // Settings Notifications
                  SettingsScreenLayout(
                    iconData: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    description: 'Manage Notifications',
                    onTap: () =>
                        context.push(SettingsNotificationScreen.kRouteName),
                  ),
                  // Settings Offline Support
                  SettingsScreenLayout(
                    iconData: Icons.wifi_off_outlined,
                    title: 'Offline Support',
                    description: 'Use the app even when online',
                    onTap: () =>
                        context.push(SettingsOfflineSupportScreen.kRouteName),
                  ),
                  // Settings About Quotely App
                  SettingsScreenLayout(
                    iconData: Icons.help_outlined,
                    title: 'About Quotely',
                    description: 'About Quotely app',
                    onTap: () => showAboutSection(context),
                  ),
                  // Settings Reset Everything to default
                  SettingsScreenLayout(
                    iconData: Icons.notifications_active_outlined,
                    title: 'Reset Settings',
                    description: 'Reset All Settings to Default',
                    onTap: () =>
                        CommonService.showNotImplementedDialog(context),
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
