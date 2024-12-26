import 'package:flutter/material.dart';

import '../components/layouts/main_layout.dart';
import '../components/motivation_monday/motivation_monday_list_component.dart';

class MotivationMondayListScreen extends StatelessWidget {
  static const kRouteName = '/motivation-monday-list';
  const MotivationMondayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'All Monday Motivation',
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 10,
          ),
          child: MotivationMondayListComponent(),
        ),
      ),
    );
  }
}
