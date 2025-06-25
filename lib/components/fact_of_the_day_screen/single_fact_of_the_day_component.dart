import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SingleFactOfTheDayComponent extends StatelessWidget {
  final DateTime factDate;
  final String category;
  final String content;

  const SingleFactOfTheDayComponent({
    super.key,
    required this.factDate,
    required this.category,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kPrimaryColor = theme.colorScheme.primary;

    return Container(
      // Use a flexible height instead of a fixed one for better adaptability
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              category.toUpperCase(),
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const Spacer(),

          // The Fact Content
          Text(
            content,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const Spacer(),

          // The Date
          Text(
            'Fact for: ${DateFormat('dd MMM, yyyy').format(factDate)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
