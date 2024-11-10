import 'package:flutter/material.dart';

class SettingsScreenLayout extends StatelessWidget {
  final String title;
  final String description;
  final IconData iconData;

  const SettingsScreenLayout({
    super.key,
    required this.title,
    required this.description,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.05),
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
                    const SizedBox(height: 2),
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
            const Flexible(
              child: Icon(
                Icons.arrow_forward_ios_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}