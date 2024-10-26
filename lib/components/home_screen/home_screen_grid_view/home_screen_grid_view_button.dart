import 'package:flutter/material.dart';

class HomeScreenGridViewButton extends StatelessWidget {
  final String title;
  final IconData iconData;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const HomeScreenGridViewButton({
    super.key,
    required this.title,
    required this.iconData,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: kPrimaryColor.withOpacity(0.2),
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
              ),
            ),
            SizedBox(width: 3),
            Icon(
              iconData,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
