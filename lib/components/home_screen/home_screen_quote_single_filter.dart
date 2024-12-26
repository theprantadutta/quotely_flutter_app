import 'package:flutter/material.dart';

class HomeScreenQuoteSingleFilter extends StatelessWidget {
  final int index;
  final String title;
  final bool doesTagExist;

  const HomeScreenQuoteSingleFilter({
    super.key,
    required this.index,
    required this.title,
    required this.doesTagExist,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: doesTagExist
            ? kPrimaryColor.withValues(alpha: 0.7)
            : Colors.transparent,
        border: Border.all(
          color: doesTagExist
              ? Colors.transparent
              : kPrimaryColor.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: doesTagExist
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}
