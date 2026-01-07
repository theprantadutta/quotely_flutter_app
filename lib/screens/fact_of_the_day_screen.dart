import 'package:flutter/material.dart';

import '../components/fact_of_the_day_screen/fact_of_the_day_component.dart';
import '../components/shared/warm_notification_screen_layout.dart';
import 'fact_of_the_day_list_screen.dart';

class FactOfTheDayScreen extends StatelessWidget {
  static const kRouteName = '/fact-of-the-day';
  const FactOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationScreenLayout(
      title: 'Fact of the Day',
      subtitle: 'Learn something new',
      icon: Icons.lightbulb_rounded,
      contentWidget: FactOfTheDayComponent(),
      allItemsRoute: FactOfTheDayListScreen.kRouteName,
      seeAllLabel: 'See All Facts',
    );
  }
}
