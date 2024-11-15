import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/layouts/main_layout.dart';

class SettingsNotificationScreen extends StatefulWidget {
  static const kRouteName = '/settings-notification';
  const SettingsNotificationScreen({super.key});

  @override
  State<SettingsNotificationScreen> createState() =>
      _SettingsNotificationState();
}

class _SettingsNotificationState extends State<SettingsNotificationScreen> {
  bool isNotificationEnabled = false;

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return MainLayout(
      title: 'Notifications',
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        child: Column(
          children: [
            Container(
              height: MediaQuery.sizeOf(context).height * 0.07,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Switch(
                    activeColor: kPrimaryColor,
                    inactiveThumbColor: kPrimaryColor.withOpacity(0.3),
                    inactiveTrackColor: kPrimaryColor.withOpacity(0.3),
                    trackColor: WidgetStateProperty.all(
                      kPrimaryColor.withOpacity(0.1),
                    ),
                    trackOutlineColor: WidgetStateProperty.all(
                      kPrimaryColor.withOpacity(0.2),
                    ),
                    value: isNotificationEnabled,
                    onChanged: (value) => setState(
                      () => isNotificationEnabled = value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Enable Notifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
