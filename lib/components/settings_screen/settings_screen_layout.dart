import 'package:flutter/material.dart';

import '../../constants/selectors.dart';

class SettingsScreenLayout extends StatelessWidget {
  final String title;
  final String description;
  final IconData iconData;
  final VoidCallback onTap;

  const SettingsScreenLayout({
    super.key,
    required this.title,
    required this.description,
    required this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.12,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          // color: kPrimaryColor.withValues(alpha: 0.05),
          gradient: kGetDefaultGradient(context),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Center(
                child: Icon(
                  iconData,
                  color: kPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              flex: 5,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: Icon(
                Icons.arrow_forward_ios_outlined,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
