import 'package:flutter/material.dart';

import '../shared/painted_card_style.dart';

/// Paints one deck card: theme-native gradient surface with a soft shadow
/// and a depth-dimming overlay for cards lower in the stack.
class DeckCardPainter extends CustomPainter {
  final PaintedCardStyle style;

  /// 0 = top card, 1..3 = deeper in the stack (dimmed slightly).
  final int depth;

  DeckCardPainter({required this.style, required this.depth});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );

    style.paintSurface(canvas, rrect, shadowBlur: depth == 0 ? 10 : 4);

    // Depth dimming for stacked cards
    if (depth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = (style.brightness == Brightness.dark
                  ? Colors.black
                  : Colors.grey.shade300)
              .withValues(alpha: 0.10 * depth),
      );
    }
  }

  @override
  bool shouldRepaint(DeckCardPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.depth != depth;
}
