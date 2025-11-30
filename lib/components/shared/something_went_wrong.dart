import 'package:flutter/material.dart';

class SomethingWentWrong extends StatelessWidget {
  final String title;
  final void Function()? onRetryPressed;

  const SomethingWentWrong({
    super.key,
    this.onRetryPressed,
    this.title = 'Something Went Wrong',
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 70, color: Colors.red[300]),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const SizedBox(
          width: 307,
          child: Text(
            'This wasn\'t supposed to happen, check your internet connection, if the problem persists, curse us :)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: onRetryPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            width: 150,
            decoration: BoxDecoration(
              // color: kPrimaryColor,
              border: Border.all(
                color: kPrimaryColor.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
