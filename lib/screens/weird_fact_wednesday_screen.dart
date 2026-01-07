import 'package:flutter/material.dart';

import '../components/shared/warm_notification_screen_layout.dart';
import '../components/weird_fact_wednesday/weird_fact_wednesday_component.dart';
import 'weird_fact_wednesday_list_screen.dart';

class WeirdFactWednesdayScreen extends StatelessWidget {
  static const String kRouteName = '/weird-fact-wednesday';
  const WeirdFactWednesdayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationScreenLayout(
      title: 'Weird Fact Wednesday',
      subtitle: 'Strange but true',
      icon: Icons.science_rounded,
      contentWidget: WeirdFactWednesdayComponent(),
      allItemsRoute: WeirdFactWednesdayListScreen.kRouteName,
      seeAllLabel: 'See All Weird Facts',
    );
  }
}
