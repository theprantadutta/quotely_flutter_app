import 'package:flutter/material.dart';

import '../components/layouts/main_layout.dart';
import '../components/quote_of_the_day_list_screen/quote_of_the_day_list_component.dart';

class DailyInspirationListScreen extends StatelessWidget {
  static const kRouteName = '/daily-inspiration-list';
  const DailyInspirationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'All Daily Inspiration',
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: QuoteOfTheDayListComponent(),
        ),
      ),
    );
  }
}
