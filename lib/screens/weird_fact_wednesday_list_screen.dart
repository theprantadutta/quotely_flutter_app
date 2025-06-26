import 'package:flutter/material.dart';

import '../components/layouts/main_layout.dart';
import '../components/weird_fact_wednesday/weird_fact_wednesday_list_component.dart';

class WeirdFactWednesdayListScreen extends StatelessWidget {
  static const String kRouteName = '/weird-fact-wednesday-list';
  const WeirdFactWednesdayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'All Weird Fact Wednesday',
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 10,
          ),
          child: WeirdFactWednesdayListComponent(),
        ),
      ),
    );
  }
}
