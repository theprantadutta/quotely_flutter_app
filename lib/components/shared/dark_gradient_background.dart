import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class DarkGradientBackground extends StatelessWidget {
  const DarkGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.1, 0.9],
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
            kHelperColor.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
