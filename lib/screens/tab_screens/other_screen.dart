import 'package:flutter/material.dart';

class OtherScreen extends StatelessWidget {
  static const kRouteName = '/other';
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text('Other Screen'),
      ),
    );
  }
}
