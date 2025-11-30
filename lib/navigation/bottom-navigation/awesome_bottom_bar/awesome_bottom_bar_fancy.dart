import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../packages/awesome_bottom_bar/src/bottom_bar_inspired_fancy.dart';
import '../../../packages/awesome_bottom_bar/tab_item.dart';

class AwesomeBottomBarFancy extends StatefulWidget {
  final int selectedIndex;
  final Function(int) updateCurrentPageIndex;
  final StyleIconFooter styleIconFooter;

  const AwesomeBottomBarFancy({
    super.key,
    required this.selectedIndex,
    required this.updateCurrentPageIndex,
    this.styleIconFooter = StyleIconFooter.divider,
  });

  @override
  State<AwesomeBottomBarFancy> createState() =>
      _AwesomeBottomBarFancyBorderLayoutState();
}

class _AwesomeBottomBarFancyBorderLayoutState
    extends State<AwesomeBottomBarFancy> {
  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    final isDarkTheme = QuotelyApp.of(context).isDarkMode;
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: BottomBarInspiredFancy(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        backgroundColor: kPrimaryColor.withValues(alpha: 0.05),
        colorSelected: kPrimaryColor,
        color: isDarkTheme ? Colors.white : Colors.black,
        iconSize: 20,
        onTap: widget.updateCurrentPageIndex,
        animated: true,
        indexSelected: widget.selectedIndex,
        styleIconFooter: StyleIconFooter.dot,
        pad: 2,
        items: const [
          TabItem(icon: Icons.home_outlined, title: 'Home'),
          TabItem(icon: Icons.favorite_outline, title: 'Favorites'),
          TabItem(icon: Icons.person_2_outlined, title: 'Authors'),
          TabItem(icon: Icons.fact_check_outlined, title: 'Facts'),
          TabItem(icon: Icons.settings_outlined, title: 'Settings'),
        ],
      ),
    );
  }
}
