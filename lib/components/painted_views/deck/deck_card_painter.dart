import 'package:flutter/material.dart';

import '../shared/paper_texture.dart';

/// Paints one deck card: rounded paper face with a drop shadow, top-edge
/// highlight, and a depth-darkening overlay for cards lower in the stack.
class DeckCardPainter extends CustomPainter {
  final Brightness brightness;
  final Color tint;

  /// 0 = top card, 1..3 = deeper in the stack (darkened slightly).
  final int depth;

  DeckCardPainter({
    required this.brightness,
    required this.tint,
    required this.depth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );

    canvas.drawShadow(
      Path()..addRRect(rrect),
      Colors.black.withValues(alpha: 0.8),
      depth == 0 ? 10 : 4,
      false,
    );

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPicture(
      PaperTextureCache.of(size: size, brightness: brightness, tint: tint),
    );

    // Depth darkening for stacked cards
    if (depth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()..color = Colors.black.withValues(alpha: 0.05 * depth),
      );
    }

    // Top edge highlight
    canvas.drawLine(
      const Offset(16, 1),
      Offset(size.width - 16, 1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(DeckCardPainter oldDelegate) =>
      oldDelegate.brightness != brightness ||
      oldDelegate.tint != tint ||
      oldDelegate.depth != depth;
}
