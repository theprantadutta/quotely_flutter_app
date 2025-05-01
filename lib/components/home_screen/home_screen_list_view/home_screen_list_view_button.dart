import 'package:flutter/material.dart';

class HomeScreenListViewButton extends StatelessWidget {
  final String title;
  final IconData iconData;
  final VoidCallback onTap;
  final bool isSelected;

  const HomeScreenListViewButton({
    super.key,
    required this.title,
    required this.iconData,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.7)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : kPrimaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : kPrimaryColor,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              iconData,
              size: 15,
              color: isSelected ? Colors.white : kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
