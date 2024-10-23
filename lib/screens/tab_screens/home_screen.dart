import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static const kRouteName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text('Home Screen'),
      ),
    );
  }
}
