import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotely_flutter_app/constants/selectors.dart';

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
      height: MediaQuery.sizeOf(context).height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: kGetDefaultGradient(context),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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

          // The Fact Content
          Text(
            content,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),

          // The Date
          Text(
            'Fact Date: ${DateFormat('dd MMM, yyyy').format(factDate)}',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SingleFactOfTheDayComponentSkeletor extends StatelessWidget {
  const SingleFactOfTheDayComponentSkeletor({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kPrimaryColor = theme.colorScheme.primary;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: kGetDefaultGradient(context),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // The Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Loading...',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),

          // The Fact Content
          Text(
            'Loading fact content here something random thing for placeholder bull...',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),

          // The Date
          Text(
            'Fact Date: 25 Jan, 2024',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
