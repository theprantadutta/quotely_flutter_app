import 'package:flutter/material.dart';

import '../shared/painted_card_style.dart';

/// Paints one opaque book page: theme-native rounded card surface with a
/// subtle "binding" hint along the left edge. Each page paints its own
/// surface so stacked pages never show through one another.
class BookPagePainter extends CustomPainter {
  final PaintedCardStyle style;

  BookPagePainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final page = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );

    // Opaque base first — pages stack during flips and must not bleed
    canvas.drawRRect(page, Paint()..color = style.surface);
    style.paintSurface(canvas, page, shadowBlur: 8);

    // Binding hint: a soft darker band along the left edge
    final binding = Rect.fromLTWH(0, 0, 18, size.height);
    canvas.save();
    canvas.clipRRect(page);
    canvas.drawRect(
      binding,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(
              alpha: style.brightness == Brightness.dark ? 0.20 : 0.06,
            ),
            Colors.transparent,
          ],
        ).createShader(binding),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BookPagePainter oldDelegate) =>
      oldDelegate.style != style;
}
