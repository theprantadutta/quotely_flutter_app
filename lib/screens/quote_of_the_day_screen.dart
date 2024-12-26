import 'package:flutter/material.dart';

import '../../components/quote_of_the_day_screen/quote_of_the_day_component.dart';
import '../../components/shared/quote_notification_screen_layout.dart';
import '../../screens/quote_of_the_day_list_screen.dart';

class QuoteOfTheDayScreen extends StatelessWidget {
  static const kRouteName = '/quote-of-the-day';
  const QuoteOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QuoteNotificationScreenLayout(
      title: 'Quote of the Day',
      quoteWidget: const QuoteOfTheDayComponent(),
      allQuoteRoute: QuoteOfTheDayListScreen.kRouteName,
    );
  }
}
