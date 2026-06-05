import 'package:flutter/material.dart';

class TopNavigationBar extends StatelessWidget {
  final String title;

  /// Optional action(s) on the right edge. The title stays visually centered
  /// via a balancing spacer on the left. Null = original centered rendering.
  final Widget? trailing;

  const TopNavigationBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    final titleText = Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: kPrimaryColor,
      ),
    );

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.06,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: trailing == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [titleText],
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Center(child: titleText),
                Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            ),
    );
  }
}
