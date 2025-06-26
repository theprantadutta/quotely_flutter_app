import 'package:flutter/material.dart';

import '../components/shared/fact_notification_screen_layout.dart';
import '../components/weird_fact_wednesday/weird_fact_wednesday_component.dart';
import 'weird_fact_wednesday_list_screen.dart';

class WeirdFactWednesdayScreen extends StatelessWidget {
  static const String kRouteName = '/weird-fact-wednesday';
  const WeirdFactWednesdayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FactNotificationScreenLayout(
      title: 'Weird Fact Wednesday',
      factWidget: WeirdFactWednesdayComponent(),
      allFactRoute: WeirdFactWednesdayListScreen.kRouteName,
    );
  }
}
