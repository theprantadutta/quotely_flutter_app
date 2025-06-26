import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/layouts/main_layout.dart';

import '../components/fact_of_the_day_list_screen/fact_of_the_day_list_component.dart';

class FactOfTheDayListScreen extends StatelessWidget {
  static const kRouteName = '/fact-of-the-list';
  const FactOfTheDayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'All Fact of the Day',
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 10,
          ),
          child: FactOfTheDayListComponent(),
        ),
      ),
    );
  }
}
