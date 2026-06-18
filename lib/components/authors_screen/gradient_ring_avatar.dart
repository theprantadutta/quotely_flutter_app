import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../shared/circle_avatar_with_fallback.dart';

/// A [CircleAvatarWithFallback] inside a vivid primary→green gradient ring —
/// the premium avatar treatment used across the Authors screen.
class GradientRingAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;
  final double ringWidth;

  const GradientRingAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.radius,
    this.ringWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Theme.of(context).primaryColor, kHelperColor],
        ),
      ),
      child: CircleAvatarWithFallback(
        name: name,
        radius: radius,
        imageUrl: imageUrl,
      ),
    );
  }
}
