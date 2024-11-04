import 'package:flutter/material.dart';

import '../../navigation/bottom-navigation/bottom_navigation_layout.dart';

class TopNavigationBar extends StatelessWidget {
  final String title;

  const TopNavigationBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.06,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => BottomNavigationLayout.of(context).gotoPreviousPage(),
            child: Icon(
              Icons.arrow_back,
              color: kPrimaryColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: kPrimaryColor,
            ),
          ),
          GestureDetector(
            onTap: () => BottomNavigationLayout.of(context).gotoNextPage(),
            child: Icon(
              Icons.arrow_forward,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
