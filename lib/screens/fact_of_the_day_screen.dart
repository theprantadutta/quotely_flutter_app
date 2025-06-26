import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/fact_of_the_day_screen/fact_of_the_day_component.dart';

import '../components/shared/fact_notification_screen_layout.dart';
import 'fact_of_the_day_list_screen.dart';

class FactOfTheDayScreen extends StatelessWidget {
  static const kRouteName = '/fact-of-the-day';
  const FactOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FactNotificationScreenLayout(
      title: 'Fact of the Day',
      factWidget: FactOfTheDayComponent(),
      allFactRoute: FactOfTheDayListScreen.kRouteName,
    );
  }
}
