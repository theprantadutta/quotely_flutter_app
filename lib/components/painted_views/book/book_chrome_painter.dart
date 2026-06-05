import 'package:flutter/material.dart';

import '../shared/painted_card_style.dart';

/// Paints the book's base: one soft, theme-colored "open spread" card with a
/// subtle center crease dividing the two pages. Modern and flat — no covers,
/// stitches, or paper texture.
class BookChromePainter extends CustomPainter {
  final PaintedCardStyle style;

  /// Breathing room between the canvas edge and the spread.
  static const double coverBorder = 6;

  BookChromePainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final spread = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        coverBorder,
        coverBorder,
        size.width - coverBorder * 2,
        size.height - coverBorder * 2,
      ),
      const Radius.circular(24),
    );

    style.paintSurface(canvas, spread, shadowBlur: 10);

    // Center crease: a soft valley where the two pages meet
    final creaseX = size.width / 2;
    final creaseRect = Rect.fromLTWH(
      creaseX - 14,
      spread.top,
      28,
      spread.height,
    );
    canvas.save();
    canvas.clipRRect(spread);
    canvas.drawRect(
      creaseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black.withValues(
              alpha: style.brightness == Brightness.dark ? 0.22 : 0.08,
            ),
            Colors.transparent,
          ],
        ).createShader(creaseRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BookChromePainter oldDelegate) =>
      oldDelegate.style != style;
}
