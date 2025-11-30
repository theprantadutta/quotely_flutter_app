import 'package:flutter/material.dart';

class SettingsMenuRowLayout extends StatelessWidget {
  final String title;
  final IconData iconData;
  final Widget? child;

  const SettingsMenuRowLayout({
    super.key,
    required this.title,
    required this.iconData,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(iconData, color: kPrimaryColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child:
                child ??
                Icon(Icons.arrow_forward_ios, color: kPrimaryColor, size: 20),
          ),
        ],
      ),
    );
  }
}
