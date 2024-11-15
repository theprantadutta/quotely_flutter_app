import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/settings_screen/appearance/dark_theme.dart';

import '../../layouts/main_layout.dart';

class AppearanceScreen extends StatelessWidget {
  static const kRouteName = '/appearance';
  const AppearanceScreen({super.key});

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
            DarkTheme(),
          ],
        ),
      ),
    );
  }
}
