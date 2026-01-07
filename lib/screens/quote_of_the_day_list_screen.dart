import 'package:flutter/material.dart';

import '../components/quote_of_the_day_list_screen/quote_of_the_day_list_component.dart';
import '../components/shared/warm_notification_screen_layout.dart';

class QuoteOfTheDayListScreen extends StatelessWidget {
  static const kRouteName = '/quote-of-the-day-list';
  const QuoteOfTheDayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WarmNotificationListLayout(
      title: 'All Quotes of the Day',
      icon: Icons.format_quote_rounded,
      listWidget: QuoteOfTheDayListComponent(),
    );
  }
}
