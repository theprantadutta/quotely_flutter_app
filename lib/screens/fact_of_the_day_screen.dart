import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/layouts/main_layout.dart';

class FactOfTheDayScreen extends StatelessWidget {
  static const kRouteName = '/fact-of-the-day';
  const FactOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Fact of the Day",
      body: Center(
        child: Text("Fact of the Day"),
      ),
    );
  }
}
