import 'package:flutter/material.dart';

class HomeScreenListViewButton extends StatelessWidget {
  final String title;
  final IconData iconData;

  const HomeScreenListViewButton({
    super.key,
    required this.title,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: kPrimaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            iconData,
            size: 15,
          ),
        ],
      ),
    );
  }
}
