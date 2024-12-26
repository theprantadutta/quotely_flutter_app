import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SingleQuoteOfTheDay extends StatelessWidget {
  final int index;
  final String author;
  final String content;
  final DateTime quoteDate;

  const SingleQuoteOfTheDay({
    super.key,
    required this.index,
    required this.author,
    required this.content,
    required this.quoteDate,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 10,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote Date: ${DateFormat('dd, MM, yyyy').format(quoteDate)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(content),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '- ${author}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SingleQuoteOfTheDaySkeletor extends StatelessWidget {
  const SingleQuoteOfTheDaySkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 10,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote Date: 2024-11-05',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
              'Heedfulness is the path to the Deathless. Heedlessness is the path to death. The heedful die not. The heedless are as if already dead.'),
          SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '- The Buddha"',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
