import 'package:flutter/material.dart';

import '../components/fact_of_the_day_list_screen/fact_of_the_day_list_component.dart';
import '../components/shared/warm_notification_screen_layout.dart';

class FactOfTheDayListScreen extends StatelessWidget {
  static const kRouteName = '/fact-of-the-list';
  const FactOfTheDayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationListLayout(
      title: 'All Facts of the Day',
      icon: Icons.lightbulb_rounded,
      listWidget: FactOfTheDayListComponent(),
    );
  }
}
