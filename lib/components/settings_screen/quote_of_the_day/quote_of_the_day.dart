import 'package:flutter/material.dart';

import '../../layouts/main_layout.dart';
import '../settings_menu_row_layout.dart';

class QuoteOfTheDay extends StatelessWidget {
  const QuoteOfTheDay({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: 'Appearance',
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 10,
        ),
        child: Column(
          children: [
            SettingsMenuRowLayout(
              title: 'See All Quote of the Day',
              iconData: Icons.format_quote_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
