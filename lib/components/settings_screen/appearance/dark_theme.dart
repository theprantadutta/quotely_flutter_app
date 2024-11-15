import 'package:flutter/material.dart';

import '../../../main.dart';

class DarkTheme extends StatefulWidget {
  const DarkTheme({super.key});

  @override
  State<DarkTheme> createState() => _DarkThemeState();
}

class _DarkThemeState extends State<DarkTheme> {
  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.07,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Switch(
            activeColor: kPrimaryColor,
            inactiveThumbColor: kPrimaryColor.withOpacity(0.3),
            inactiveTrackColor: kPrimaryColor.withOpacity(0.3),
            trackColor: WidgetStateProperty.all(
              kPrimaryColor.withOpacity(0.1),
            ),
            trackOutlineColor: WidgetStateProperty.all(
              kPrimaryColor.withOpacity(0.2),
            ),
            value: MyApp.of(context).isDarkMode,
            onChanged: (value) => MyApp.of(context).changeTheme(
              value ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Set Dark Theme',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
