import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  static const kRouteName = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text('Settings Screen'),
      ),
    );
  }
}