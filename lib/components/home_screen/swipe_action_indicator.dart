import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../../theme/colors/app_colors.dart';

/// Visual feedback indicators that appear during swipe gestures
class SwipeActionIndicator extends StatelessWidget {
  final CardSwiperDirection? direction;
  final AppColorScheme colors;

  const SwipeActionIndicator({
    super.key,
    this.direction,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left indicator (Skip)
        Positioned(
          left: 24,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: direction == CardSwiperDirection.left ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: direction == CardSwiperDirection.left ? 1.0 : 0.8,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.textMuted.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      size: 32,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Right indicator (Favorite)
        Positioned(
          right: 24,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: direction == CardSwiperDirection.right ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: direction == CardSwiperDirection.right ? 1.0 : 0.8,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 32,
                      color: colors.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A smaller inline indicator for showing swipe direction hints
class SwipeDirectionHint extends StatelessWidget {
  final bool showLeft;
  final bool showRight;
  final AppColorScheme colors;

  const SwipeDirectionHint({
    super.key,
    this.showLeft = true,
    this.showRight = true,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showLeft)
            _HintChip(
              icon: Icons.chevron_left_rounded,
              label: 'Skip',
              colors: colors,
              isLeft: true,
            )
          else
            const SizedBox.shrink(),
          if (showRight)
            _HintChip(
              icon: Icons.chevron_right_rounded,
              label: 'Favorite',
              iconColor: colors.error,
              colors: colors,
              isLeft: false,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final AppColorScheme colors;
  final bool isLeft;

  const _HintChip({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.colors,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      if (isLeft)
        Icon(
          icon,
          size: 18,
          color: iconColor ?? colors.textMuted,
        ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colors.textMuted,
        ),
      ),
      if (!isLeft)
        Icon(
          icon,
          size: 18,
          color: iconColor ?? colors.textMuted,
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
