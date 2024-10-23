import 'package:flutter/material.dart';

class QuoteOfTheDayScreen extends StatelessWidget {
  static const kRouteName = '/quote-of-the-day';
  const QuoteOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text('Quote of the Day Screen'),
      ),
    );
  }
}
