import 'package:flutter/material.dart';

import '../components/motivation_monday/motivation_monday_component.dart';
import '../components/shared/quote_notification_screen_layout.dart';
import '../screens/motivation_monday_list_screen.dart';

class MotivationMondayScreen extends StatelessWidget {
  static const kRouteName = '/motivation-monday';
  const MotivationMondayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QuoteNotificationScreenLayout(
      title: 'Motivation Monday',
      quoteWidget: const MotivationMondayComponent(),
      allQuoteRoute: MotivationMondayListScreen.kRouteName,
    );
  }
}
