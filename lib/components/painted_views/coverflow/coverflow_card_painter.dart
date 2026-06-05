import 'package:flutter/material.dart';

import '../shared/painted_card_style.dart';

/// Paints one coverflow card's chrome: theme-native gradient card face and a
/// mirrored reflection fading out beneath it (classic coverflow look). The
/// reflection lives inside the same canvas, so it inherits the parent's 3D
/// rotation automatically.
class CoverflowCardPainter extends CustomPainter {
  final PaintedCardStyle style;

  /// Fraction of total height occupied by the card face (rest = gap +
  /// reflection).
  static const double cardFraction = 0.74;
  static const double gapFraction = 0.02;

  CoverflowCardPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final cardHeight = size.height * cardFraction;
    final cardRect = Rect.fromLTWH(0, 0, size.width, cardHeight);
    final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(20));

    style.paintSurface(canvas, rrect, shadowBlur: 8);

    // Reflection: mirrored card face fading out via dstIn gradient, bounded
    // saveLayer keeps the cost confined to the small reflection rect.
    final gap = size.height * gapFraction;
    final reflectionTop = cardHeight + gap;
    final reflectionHeight = size.height - reflectionTop;
    if (reflectionHeight <= 0) return;
    final reflectionRect = Rect.fromLTWH(
      0,
      reflectionTop,
      size.width,
      reflectionHeight,
    );

    canvas.saveLayer(reflectionRect, Paint());
    canvas.save();
    // Mirror about the midline between card bottom and reflection top:
    // card pixel y maps to (2*cardHeight + gap) - y, so the card's bottom
    // edge lands exactly at the reflection's top edge.
    canvas.translate(0, 2 * cardHeight + gap);
    canvas.scale(1, -1);
    style.paintSurface(canvas, rrect, shadowBlur: 0);
    canvas.restore();

    // Fade the mirrored image out quickly
    canvas.drawRect(
      reflectionRect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.transparent,
          ],
          stops: const [0.0, 0.85],
        ).createShader(reflectionRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CoverflowCardPainter oldDelegate) =>
      oldDelegate.style != style;
}
