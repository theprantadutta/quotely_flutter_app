import 'package:flutter/material.dart';

import '../components/daily_brain_food_screen/daily_brain_food_component.dart';
import '../components/shared/warm_notification_screen_layout.dart';
import 'daily_brain_food_list_screen.dart';

class DailyBrainFoodScreen extends StatelessWidget {
  static const String kRouteName = '/daily-brain-food';
  const DailyBrainFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationScreenLayout(
      title: 'Daily Brain Food',
      subtitle: 'Feed your curiosity',
      icon: Icons.psychology_rounded,
      contentWidget: DailyBrainFoodComponent(),
      allItemsRoute: DailyBrainFoodListScreen.kRouteName,
      seeAllLabel: 'See All Brain Food',
    );
  }
}
