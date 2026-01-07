import 'package:flutter/material.dart';

import '../components/daily_inspiration_screen/daily_inspiration_component.dart';
import '../components/shared/warm_notification_screen_layout.dart';
import '../screens/daily_inspiration_list_screen.dart';

class DailyInspirationScreen extends StatelessWidget {
  static const kRouteName = '/daily-inspiration';
  const DailyInspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationScreenLayout(
      title: 'Daily Inspiration',
      subtitle: 'Start your day inspired',
      icon: Icons.wb_sunny_rounded,
      contentWidget: DailyInspirationComponent(),
      allItemsRoute: DailyInspirationListScreen.kRouteName,
      seeAllLabel: 'See All Inspirations',
    );
  }
}
