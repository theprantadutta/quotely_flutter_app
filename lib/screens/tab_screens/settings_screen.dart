// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quotely_flutter_app/constants/selectors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/settings_screen/appearance/appearance_screen.dart';
import '../../../components/settings_screen/settings_screen_layout.dart';
import '../../../components/shared/top_navigation_bar.dart';
import '../../../screens/settings_notification_screen.dart';
import '../../../screens/settings_offline_support_screen.dart';
import '../../services/common_service.dart';

class SettingsScreen extends StatelessWidget {
  static const kRouteName = '/settings';
  const SettingsScreen({super.key});

  Future<void> showAboutSection(BuildContext context) async {
    final platform = await PackageInfo.fromPlatform();
    final version = platform.version;
    final kPrimaryColor = Theme.of(context).primaryColor;
    final currentYear = DateFormat('yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: kPrimaryColor),
            const SizedBox(width: 8),
            Text(
              'About Quotely App',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/quotely_logo.png'),
              ),
              const SizedBox(height: 20),
              Text(
                'Version: $version',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quotely is a Flutter app designed for quote enthusiasts.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Developed & Maintained By:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse('https://pranta.dev');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: kGetDefaultGradient(context),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pranta Dutta',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: kPrimaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '© $currentYear Pranta Dutta. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.05),
                    border: Border.all(
                      color: kPrimaryColor.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  gotoAScreen(BuildContext context, String route) {
    try {
      Future.delayed(Duration.zero, () async {
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
                    onTap: () =>
                        gotoAScreen(context, AppearanceScreen.kRouteName),
                  ),
                  // Settings Notifications
                  SettingsScreenLayout(
                    iconData: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    description: 'Manage Notifications',
                    onTap: () => gotoAScreen(
                        context, SettingsNotificationScreen.kRouteName),
                  ),
                  // Settings Offline Support
                  SettingsScreenLayout(
                    iconData: Icons.wifi_off_outlined,
                    title: 'Offline Support',
                    description: 'Use the app even when online',
                    onTap: () => gotoAScreen(
                        context, SettingsOfflineSupportScreen.kRouteName),
                  ),
                  // Settings Add A Quote
                  SettingsScreenLayout(
                    iconData: Icons.add_box_outlined,
                    title: 'Add A Quote',
                    description: 'Add A Quote with Authors and Tags',
                    onTap: () =>
                        CommonService.showNotImplementedDialog(context),
                    // onTap: () => gotoAScreen(
                    //     context, SettingsOfflineSupportScreen.kRouteName),
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
