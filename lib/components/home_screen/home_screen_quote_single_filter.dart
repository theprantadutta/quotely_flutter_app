import 'package:flutter/material.dart';

class HomeScreenQuoteSingleFilter extends StatelessWidget {
  final int index;
  final String title;

  const HomeScreenQuoteSingleFilter(
      {super.key, required this.index, required this.title});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(
          color: kPrimaryColor.withOpacity(0.4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
