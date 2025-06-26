import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/daily_brain_food_screen/daily_brain_food_component.dart';

import '../components/shared/fact_notification_screen_layout.dart';
import 'daily_brain_food_list_screen.dart';

class DailyBrainFoodScreen extends StatelessWidget {
  static const String kRouteName = '/daily-brain-food';
  const DailyBrainFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FactNotificationScreenLayout(
      title: 'Daily Brain Food',
      factWidget: DailyBrainFoodComponent(),
      allFactRoute: DailyBrainFoodListScreen.kRouteName,
    );
  }
}
