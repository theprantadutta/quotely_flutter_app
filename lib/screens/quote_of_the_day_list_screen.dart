import 'package:flutter/material.dart';

import '../components/layouts/main_layout.dart';
import '../components/quote_of_the_day_list_screen/quote_of_the_day_list_component.dart';

class QuoteOfTheDayListScreen extends StatelessWidget {
  static const kRouteName = '/quote-of-the-day-list';
  const QuoteOfTheDayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'All Quote of the Day',
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: QuoteOfTheDayListComponent(),
        ),
      ),
    );
  }
}
