import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/daily_inspiration_screen/daily_inspiration_component.dart';
import 'package:quotely_flutter_app/screens/daily_inspiration_list_screen.dart';

import '../components/shared/quote_notification_screen_layout.dart';

class DailyInspirationScreen extends StatelessWidget {
  static const kRouteName = '/daily-inspiration';
  const DailyInspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QuoteNotificationScreenLayout(
      title: 'Daily Inspiration',
      quoteWidget: const DailyInspirationComponent(),
      allQuoteRoute: DailyInspirationListScreen.kRouteName,
    );
  }
}
