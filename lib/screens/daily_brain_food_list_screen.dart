import 'package:flutter/material.dart';

import '../components/daily_brain_food_screen/daily_brain_food_list_component.dart';
import '../components/layouts/main_layout.dart';

class DailyBrainFoodListScreen extends StatelessWidget {
  static const String kRouteName = '/daily-brain-food-list';
  const DailyBrainFoodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'All Daily Brain Food',
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: DailyBrainFoodListComponent(),
        ),
      ),
    );
  }
}
