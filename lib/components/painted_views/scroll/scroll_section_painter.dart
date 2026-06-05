import 'package:flutter/material.dart';

import '../shared/painted_card_style.dart';

/// Paints one feed item in scroll mode: a theme-gradient card connected to
/// its neighbors by an accent timeline rail on the left, with a node dot per
/// item (filled red when favorited) — a modern "reading thread".
class ScrollSectionPainter extends CustomPainter {
  final PaintedCardStyle style;
  final bool isFirst;
  final bool isLast;
  final bool isFavorite;

  static const double railX = 22;

  ScrollSectionPainter({
    required this.style,
    required this.isFirst,
    required this.isLast,
    required this.isFavorite,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Card body, inset to leave room for the rail
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(38, 4, size.width - 44, size.height - 12),
      const Radius.circular(18),
    );
    style.paintSurface(canvas, card, shadowBlur: 5);

    // Timeline rail
    final railPaint = Paint()
      ..color = style.accent.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    final nodeY = size.height / 2;
    if (!isFirst) {
      canvas.drawLine(Offset(railX, 0), Offset(railX, nodeY - 9), railPaint);
    }
    if (!isLast) {
      canvas.drawLine(
        Offset(railX, nodeY + 9),
        Offset(railX, size.height),
        railPaint,
      );
    }

    // Node dot: ring normally, filled red-accent when favorited
    if (isFavorite) {
      canvas.drawCircle(
        Offset(railX, nodeY),
        6,
        Paint()..color = Colors.redAccent,
      );
      canvas.drawCircle(
        Offset(railX, nodeY),
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.redAccent.withValues(alpha: 0.35),
      );
    } else {
      canvas.drawCircle(
        Offset(railX, nodeY),
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = style.accent.withValues(alpha: 0.7),
      );
    }

    // Connector from rail to card
    canvas.drawLine(
      Offset(railX + (isFavorite ? 9 : 5), nodeY),
      Offset(38, nodeY),
      Paint()
        ..color = style.accent.withValues(alpha: 0.25)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(ScrollSectionPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast ||
      oldDelegate.isFavorite != isFavorite;
}
