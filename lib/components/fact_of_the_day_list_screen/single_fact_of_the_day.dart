import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SingleFactOfTheDay extends StatelessWidget {
  final String category;
  final String content;
  final DateTime factDate;

  const SingleFactOfTheDay({
    super.key,
    required this.category,
    required this.content,
    required this.factDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kPrimaryColor = theme.colorScheme.primary;

    // This container follows the same style as your SingleQuoteOfTheDay
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.05),
        border: Border.all(
          color: kPrimaryColor.withOpacity(0.15),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The date the fact was featured
          Text(
            'Fact for: ${DateFormat('dd MMM, yyyy').format(factDate)}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // The main fact content
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),

          // The category chip, aligned to the right
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SingleFactOfTheDaySkeletor extends StatelessWidget {
  const SingleFactOfTheDaySkeletor({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kPrimaryColor = theme.colorScheme.primary;

    // This container follows the same style as your SingleQuoteOfTheDay
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.05),
        border: Border.all(
          color: kPrimaryColor.withOpacity(0.15),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The date the fact was featured
          Text(
            'Fact for: 20 Oct, 2023',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // The main fact content
          Text(
            'This is a placeholder for the fact content. It will be replaced with actual data when available.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),

          // The category chip, aligned to the right
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
