import 'package:flutter/material.dart';

class SwitchSettingsLayout extends StatelessWidget {
  final String title;
  final bool value;
  final Function(bool value) onSwitchChanged;

  const SwitchSettingsLayout({
    super.key,
    required this.title,
    required this.value,
    required this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.07,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Switch(
            activeColor: kPrimaryColor,
            inactiveThumbColor: kPrimaryColor.withValues(alpha: 0.3),
            inactiveTrackColor: kPrimaryColor.withValues(alpha: 0.3),
            trackColor: WidgetStateProperty.all(
              kPrimaryColor.withValues(alpha: 0.1),
            ),
            trackOutlineColor: WidgetStateProperty.all(
              kPrimaryColor.withValues(alpha: 0.2),
            ),
            value: value,
            onChanged: onSwitchChanged,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
