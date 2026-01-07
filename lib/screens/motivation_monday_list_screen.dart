import 'package:flutter/material.dart';

import '../components/motivation_monday/motivation_monday_list_component.dart';
import '../components/shared/warm_notification_screen_layout.dart';

class MotivationMondayListScreen extends StatelessWidget {
  static const kRouteName = '/motivation-monday-list';
  const MotivationMondayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationListLayout(
      title: 'All Monday Motivations',
      icon: Icons.rocket_launch_rounded,
      listWidget: MotivationMondayListComponent(),
    );
  }
}
