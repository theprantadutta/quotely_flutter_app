import 'package:flutter/material.dart';

import '../components/daily_inspiration_screen/daily_inspiration_list_component.dart';
import '../components/shared/warm_notification_screen_layout.dart';

class DailyInspirationListScreen extends StatelessWidget {
  static const kRouteName = '/daily-inspiration-list';
  const DailyInspirationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationListLayout(
      title: 'All Daily Inspirations',
      icon: Icons.wb_sunny_rounded,
      listWidget: DailyInspirationListComponent(),
    );
  }
}
