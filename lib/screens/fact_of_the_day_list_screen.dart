import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/layouts/main_layout.dart';

class FactOfTheDayListScreen extends StatelessWidget {
  static const kRouteName = '/fact-of-the-list';
  const FactOfTheDayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'All Fact of the Day',
      body: Center(
        child: Text(
          'All Fact of the Day',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
