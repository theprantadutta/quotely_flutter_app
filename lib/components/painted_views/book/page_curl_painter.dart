import 'dart:math';

import 'package:flutter/material.dart';

import '../shared/painted_card_style.dart';

/// Paints the animated page fold during a flip. Pragmatic "mirror fold"
/// rather than a true cylinder shader:
///
/// With flip progress `t`, the crease line sits at `x_f = xR - t*pageW`,
/// sweeping from the book's right edge to the spine. The lifted part of the
/// turning page is mirrored about the crease: its back face occupies
/// `[2*x_f - xR, x_f]`, drawn with a bowed outer edge (quadratic Bézier) and
/// a 3-stop "cylinder highlight" gradient, plus cast + contact shadows.
///
/// The hosting widget clips the current spread's widgets to `x < x_f` and
/// shows the next spread beneath, so this painter only adds the fold itself.
class PageCurlPainter extends CustomPainter {
  /// Flip progress 0..1, driven by drag/settle animation.
  final Animation<double> progress;

  final PaintedCardStyle style;

  /// Book page bounds inside the canvas (excludes the outer inset).
  final Rect pagesRect;

  PageCurlPainter({
    required this.progress,
    required this.style,
    required this.pagesRect,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0.001 || t >= 0.999) return;

    // The turning page's back face uses the same surface family as the card
    final base = style.surface;
    final isDark = style.brightness == Brightness.dark;

    final xR = pagesRect.right;
    final pageW = pagesRect.width / 2;
    final xF = xR - t * pageW; // crease line
    final xB = 2 * xF - xR; // mirrored outer edge
    final top = pagesRect.top;
    final bottom = pagesRect.bottom;
    final midY = (top + bottom) / 2;

    // How far the outer edge has travelled — bow strength peaks mid-flip
    final bow = 0.18 * (xF - xB).abs() * sin(pi * t).clamp(0.2, 1.0);

    // Back-of-page path: straight crease edge on the right, bowed outer
    // edge on the left, slight diagonal tilt (top corner leads the turn).
    final tilt = 8.0 * sin(pi * t);
    final backPath = Path()
      ..moveTo(xF, top)
      ..lineTo(xF, bottom)
      ..lineTo(xB + tilt, bottom - 2)
      ..quadraticBezierTo(xB - bow, midY, xB - tilt, top + 2)
      ..close();

    // Lift shadow cast onto whatever is beneath the turning page
    canvas.drawShadow(
      backPath,
      Colors.black.withValues(alpha: 0.8),
      6 + 10 * sin(pi * t),
      false,
    );

    // Back face: cylinder-highlight gradient across the fold
    canvas.drawPath(
      backPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(base, Colors.black, isDark ? 0.18 : 0.08)!,
            Color.lerp(base, Colors.white, isDark ? 0.06 : 0.35)!,
            Color.lerp(base, Colors.black, isDark ? 0.24 : 0.12)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTRB(xB - bow, top, xF, bottom)),
    );

    // Crease edge line
    canvas.drawLine(
      Offset(xF, top),
      Offset(xF, bottom),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..strokeWidth = 1,
    );

    // Contact shadow on the revealed page, just right of the crease
    final contactRect = Rect.fromLTRB(xF, top, min(xF + 24, xR), bottom);
    canvas.drawRect(
      contactRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: 0.18 * sin(pi * t)),
            Colors.transparent,
          ],
        ).createShader(contactRect),
    );
  }

  @override
  bool shouldRepaint(PageCurlPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.pagesRect != pagesRect;
}

/// Clips the current spread's widget content to everything left of the
/// crease line, so the lifted portion of the turning page disappears and
/// the next spread shows through underneath.
class PageCurlClipper extends CustomClipper<Path> {
  final double t;
  final Rect pagesRect;

  PageCurlClipper({required this.t, required this.pagesRect});

  @override
  Path getClip(Size size) {
    if (t <= 0.001) return Path()..addRect(Offset.zero & size);
    final pageW = pagesRect.width / 2;
    final xF = pagesRect.right - t * pageW;
    return Path()..addRect(Rect.fromLTRB(0, 0, xF, size.height));
  }

  @override
  bool shouldReclip(PageCurlClipper oldClipper) =>
      oldClipper.t != t || oldClipper.pagesRect != pagesRect;
}
