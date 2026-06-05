import 'package:flutter/material.dart';

import 'content_view_mode.dart';

/// Static mini-preview of a view mode, used by the picker bottom sheet.
/// Pure chrome sketches — never repaints.
class ViewModePreviewPainter extends CustomPainter {
  final ContentViewMode mode;
  final Color paper;
  final Color accent;

  ViewModePreviewPainter({
    required this.mode,
    required this.paper,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paperPaint = Paint()..color = paper;
    final linePaint = Paint()..color = accent.withValues(alpha: 0.45);

    void textBars(Rect rect, int count) {
      for (var i = 0; i < count; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              rect.left + 8,
              rect.top + 10 + i * 9,
              (rect.width - 16) * (i == count - 1 ? 0.55 : 0.9),
              4,
            ),
            const Radius.circular(2),
          ),
          linePaint,
        );
      }
    }

    switch (mode) {
      case ContentViewMode.book:
        final book = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width * 0.84,
          height: size.height * 0.74,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(book, const Radius.circular(6)),
          paperPaint,
        );
        // Spine
        canvas.drawLine(
          Offset(book.center.dx, book.top + 4),
          Offset(book.center.dx, book.bottom - 4),
          Paint()
            ..color = accent.withValues(alpha: 0.6)
            ..strokeWidth = 1.5,
        );
        textBars(
          Rect.fromLTWH(book.left, book.top, book.width / 2, book.height),
          3,
        );
        // Curl corner on the right page
        final curl = Path()
          ..moveTo(book.right, book.bottom - 18)
          ..lineTo(book.right, book.bottom)
          ..lineTo(book.right - 18, book.bottom)
          ..close();
        canvas.drawPath(curl, Paint()..color = accent.withValues(alpha: 0.5));

      case ContentViewMode.deck:
        final center = size.center(Offset.zero);
        for (var i = 2; i >= 0; i--) {
          canvas.save();
          canvas.translate(center.dx, center.dy + i * 5.0);
          canvas.rotate((i - 1) * 0.06);
          final card = Rect.fromCenter(
            center: Offset.zero,
            width: size.width * 0.52,
            height: size.height * 0.66,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(card, const Radius.circular(8)),
            i == 0
                ? paperPaint
                : (Paint()..color = paper.withValues(alpha: 0.7)),
          );
          if (i == 0) textBars(card, 3);
          canvas.restore();
        }

      case ContentViewMode.scroll:
        final body = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width * 0.56,
          height: size.height * 0.62,
        );
        canvas.drawRect(body, paperPaint);
        textBars(body, 4);
        // Rolls top and bottom
        for (final y in [body.top - 6, body.bottom + 6]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(body.center.dx, y),
                width: body.width * 1.25,
                height: 12,
              ),
              const Radius.circular(6),
            ),
            Paint()..color = accent.withValues(alpha: 0.65),
          );
        }

      case ContentViewMode.coverflow:
        final center = size.center(Offset.zero) - const Offset(0, 6);
        // Side cards: skewed parallelograms
        for (final dir in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(center.dx + dir * size.width * 0.30, center.dy);
          canvas.transform(
            (Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateY(-dir * 0.9))
                .storage,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 34, height: 46),
              const Radius.circular(4),
            ),
            Paint()..color = paper.withValues(alpha: 0.6),
          );
          canvas.restore();
        }
        // Center card + reflection
        final card = Rect.fromCenter(
          center: center,
          width: 40,
          height: 50,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(card, const Radius.circular(5)),
          paperPaint,
        );
        textBars(card, 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(card.left, card.bottom + 3, card.width, 10),
            const Radius.circular(3),
          ),
          Paint()..color = paper.withValues(alpha: 0.25),
        );
    }
  }

  @override
  bool shouldRepaint(ViewModePreviewPainter oldDelegate) =>
      oldDelegate.mode != mode ||
      oldDelegate.paper != paper ||
      oldDelegate.accent != accent;
}
