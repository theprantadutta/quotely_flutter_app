import 'package:flutter/material.dart';

import '../shared/paper_texture.dart';

/// Paints the static book chrome: leather cover border, paper on both pages,
/// stacked page-edge arcs, and the stitched spine valley down the center.
/// Everything here is static per theme — cheap to repaint, heavy parts cached.
class BookChromePainter extends CustomPainter {
  final Brightness brightness;
  final Color tint;

  static const double coverBorder = 10;

  BookChromePainter({required this.brightness, required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final cover = Color.lerp(tint, Colors.black, isDark ? 0.7 : 0.6)!;
    final pagesRect = Rect.fromLTWH(
      coverBorder,
      coverBorder,
      size.width - coverBorder * 2,
      size.height - coverBorder * 2,
    );
    final spineX = size.width / 2;

    // Leather cover behind everything
    final coverRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    canvas.drawShadow(
      Path()..addRRect(coverRRect),
      Colors.black.withValues(alpha: 0.8),
      10,
      false,
    );
    canvas.drawRRect(
      coverRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(cover, Colors.white, 0.08)!, cover],
        ).createShader(Offset.zero & size),
    );

    // Stacked page edges: thin offset lines along outer page borders
    final edgePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 4; i++) {
      final inset = coverBorder - i * 1.8;
      if (inset < 0) break;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - inset * 2,
            size.height - inset * 2,
          ),
          const Radius.circular(8),
        ),
        edgePaint,
      );
    }

    // Paper on both pages
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(pagesRect, const Radius.circular(6)),
    );
    canvas.drawPicture(
      PaperTextureCache.of(
        size: pagesRect.size,
        brightness: brightness,
        tint: tint,
      ),
    );

    // Spine valley: inner shadows falling into the gutter from both sides
    const gutterWidth = 18.0;
    for (final leftSide in [true, false]) {
      final gutter = Rect.fromLTWH(
        leftSide ? spineX - gutterWidth : spineX,
        pagesRect.top,
        gutterWidth,
        pagesRect.height,
      );
      canvas.drawRect(
        gutter,
        Paint()
          ..shader = LinearGradient(
            begin: leftSide ? Alignment.centerLeft : Alignment.centerRight,
            end: leftSide ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.12),
            ],
          ).createShader(gutter),
      );
    }

    // Stitches: two dashed thread rows straddling the spine
    final stitchPaint = Paint()
      ..color = (isDark ? const Color(0xFF8A7A5E) : const Color(0xFF6B5B3E))
          .withValues(alpha: 0.65)
      ..strokeWidth = 1.4;
    for (final dx in [-3.0, 3.0]) {
      var y = pagesRect.top + 8;
      while (y < pagesRect.bottom - 8) {
        canvas.drawLine(
          Offset(spineX + dx, y),
          Offset(spineX + dx, y + 6),
          stitchPaint,
        );
        y += 11;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BookChromePainter oldDelegate) =>
      oldDelegate.brightness != brightness || oldDelegate.tint != tint;
}
