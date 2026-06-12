import 'package:flutter/material.dart';

import 'aurora_background.dart';

/// Initial-load / load-more placeholder: one card-shaped pane with pulsing
/// text bars over the same drifting aurora as the loaded card.
class CarouselSkeletonCard extends StatefulWidget {
  const CarouselSkeletonCard({super.key});

  @override
  State<CarouselSkeletonCard> createState() => _CarouselSkeletonCardState();
}

class _CarouselSkeletonCardState extends State<CarouselSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Same drifting aurora as the loaded card.
            Positioned.fill(child: AuroraBackground(isDark: isDark)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final alpha = 0.45 + 0.30 * _pulse.value;
                  final barColor = (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.10 * alpha + 0.04);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final width in const [1.0, 0.95, 0.98, 0.90, 0.60])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: FractionallySizedBox(
                            widthFactor: width,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
