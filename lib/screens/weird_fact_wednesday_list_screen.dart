import 'package:flutter/material.dart';

import '../components/shared/warm_notification_screen_layout.dart';
import '../components/weird_fact_wednesday/weird_fact_wednesday_list_component.dart';

class WeirdFactWednesdayListScreen extends StatelessWidget {
  static const String kRouteName = '/weird-fact-wednesday-list';
  const WeirdFactWednesdayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationListLayout(
      title: 'All Weird Facts',
      icon: Icons.science_rounded,
      listWidget: WeirdFactWednesdayListComponent(),
    );
  }
}
