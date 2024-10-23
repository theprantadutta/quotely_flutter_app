import 'package:animate_do/animate_do.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:flutter/material.dart';

class AwesomeBottomBarSoloman extends StatefulWidget {
  final int selectedIndex;
  final Function(int) updateCurrentPageIndex;
  final StyleIconFooter styleIconFooter;

  const AwesomeBottomBarSoloman({
    super.key,
    required this.selectedIndex,
    required this.updateCurrentPageIndex,
    this.styleIconFooter = StyleIconFooter.divider,
  });

  @override
  State<AwesomeBottomBarSoloman> createState() =>
      _AwesomeBottomBarFancyBorderLayoutState();
}

class _AwesomeBottomBarFancyBorderLayoutState
    extends State<AwesomeBottomBarSoloman> {
  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    // final isDarkTheme = MyApp.of(context).isDarkMode;
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: BottomBarInspiredFancy(
        backgroundColor: kPrimaryColor.withOpacity(0.05),
        colorSelected: kPrimaryColor,
        // color: isDarkTheme ? Colors.white : Colors.black,
        color: Colors.black,
        // borderRadius: BorderRadius.circular(50),
        iconSize: 20,
        onTap: widget.updateCurrentPageIndex,
        animated: true,
        indexSelected: widget.selectedIndex,
        styleIconFooter: StyleIconFooter.dot,
        borderRadius: BorderRadius.circular(15),
        // styleIconFooter: widget.styleIconFooter,
        // itemStyle: ItemStyle.circle,
        // chipStyle: ChipStyle(
        //   convexBridge: true,
        //   background: kPrimaryColor,
        // ),
        // radius: 20.0,
        pad: 2,
        items: const [
          TabItem(
            icon: Icons.home_outlined,
            title: 'Home',
          ),
          TabItem(
            icon: Icons.favorite_outline,
            title: 'Favourites',
          ),
          TabItem(
            icon: Icons.menu_book_outlined,
            title: 'Quote',
          ),
          TabItem(
            icon: Icons.info_outlined,
            title: 'Info',
          ),
        ],
      ),
    );
  }
}
