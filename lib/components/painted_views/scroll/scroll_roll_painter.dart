import 'package:flutter/material.dart';

/// Paints the rolled-up cylinder at the top/bottom of the parchment: a
/// horizontal roll body with curvature gradient bands, concentric-ellipse
/// end caps (the paper spiral seen side-on), and protruding wooden dowel
/// knobs. The band gradient shifts with [scrollShift] so the roll appears
/// to rotate as the user scrolls.
class ScrollRollPainter extends CustomPainter {
  final Brightness brightness;
  final Color tint;
  final double scrollShift; // 0..1, derived from scroll offset
  final bool flipped; // bottom roll mirrors the shadow direction

  ScrollRollPainter({
    required this.brightness,
    required this.tint,
    required this.scrollShift,
    this.flipped = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final paper = Color.lerp(
      isDark ? const Color(0xFF2B2722) : const Color(0xFFEDE3CC),
      tint,
      0.08,
    )!;
    final dark = Color.lerp(paper, Colors.black, isDark ? 0.45 : 0.28)!;
    final light = Color.lerp(paper, Colors.white, isDark ? 0.10 : 0.35)!;
    final wood = isDark ? const Color(0xFF4A3526) : const Color(0xFF6B4A2F);

    final knobWidth = size.width * 0.045;
    final bodyRect = Rect.fromLTWH(
      knobWidth,
      size.height * 0.12,
      size.width - knobWidth * 2,
      size.height * 0.76,
    );

    // Wooden dowel knobs protruding from both ends
    final knobPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(wood, Colors.white, 0.25)!,
          wood,
          Color.lerp(wood, Colors.black, 0.3)!,
        ],
      ).createShader(bodyRect);
    for (final x in [0.0, size.width - knobWidth]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            bodyRect.top + bodyRect.height * 0.22,
            knobWidth,
            bodyRect.height * 0.56,
          ),
          const Radius.circular(4),
        ),
        knobPaint,
      );
    }

    // Cast shadow toward the parchment
    final shadowPath = Path()..addRect(bodyRect);
    canvas.drawShadow(
      shadowPath,
      Colors.black.withValues(alpha: 0.6),
      flipped ? -4 : 4,
      false,
    );

    // Roll body: curvature bands, shifted by scroll for a rotation illusion
    final shift = (scrollShift % 1) * 0.06;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(bodyRect.height / 2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [dark, light, dark],
          stops: [0.0 + shift, 0.45 + shift, 1.0],
        ).createShader(bodyRect),
    );

    // End caps: 3 concentric ellipses = the rolled-paper spiral cross-section
    for (final centerX in [bodyRect.left, bodyRect.right]) {
      for (var i = 0; i < 3; i++) {
        final radiusY = bodyRect.height / 2 * (1 - i * 0.28);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX, bodyRect.center.dy),
            width: radiusY * 0.66,
            height: radiusY * 2,
          ),
          Paint()..color = i.isEven ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ScrollRollPainter oldDelegate) =>
      oldDelegate.scrollShift != scrollShift ||
      oldDelegate.brightness != brightness ||
      oldDelegate.tint != tint;
}
