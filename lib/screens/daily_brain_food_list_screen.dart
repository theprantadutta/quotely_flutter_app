import 'package:flutter/material.dart';

import '../components/daily_brain_food_screen/daily_brain_food_list_component.dart';
import '../components/shared/warm_notification_screen_layout.dart';

class DailyBrainFoodListScreen extends StatelessWidget {
  static const String kRouteName = '/daily-brain-food-list';
  const DailyBrainFoodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationListLayout(
      title: 'All Daily Brain Food',
      icon: Icons.psychology_rounded,
      listWidget: DailyBrainFoodListComponent(),
    );
  }
}
