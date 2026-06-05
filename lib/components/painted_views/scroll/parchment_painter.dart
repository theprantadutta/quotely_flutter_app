import 'dart:math';

import 'package:flutter/material.dart';

import '../shared/paper_texture.dart';

/// Paints one parchment segment: cached paper texture plus seeded torn
/// side edges and burnt-edge gradients, with a faint divider rule at the
/// bottom separating it from the next item.
class ParchmentPainter extends CustomPainter {
  final Brightness brightness;
  final Color tint;
  final int seed;
  final bool drawDivider;

  ParchmentPainter({
    required this.brightness,
    required this.tint,
    required this.seed,
    this.drawDivider = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final isDark = brightness == Brightness.dark;
    final burnt = isDark
        ? const Color(0xFF1A130C)
        : const Color(0xFF6B4A2F);

    // Torn side silhouettes: jittered polylines subtracted from the rect
    // so the paper has irregular hand-torn edges.
    final leftEdge = _tornEdge(size, rnd, left: true);
    final rightEdge = _tornEdge(size, rnd, left: false);
    final clip = Path.combine(
      PathOperation.difference,
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        leftEdge,
      ),
      rightEdge,
    );

    canvas.save();
    canvas.clipPath(clip);
    canvas.drawPicture(
      PaperTextureCache.of(size: size, brightness: brightness, tint: tint),
    );

    // Burnt side strips fading inward
    for (final (start, end) in [
      (Alignment.centerLeft, Alignment.centerRight),
      (Alignment.centerRight, Alignment.centerLeft),
    ]) {
      final strip = start == Alignment.centerLeft
          ? Rect.fromLTWH(0, 0, 14, size.height)
          : Rect.fromLTWH(size.width - 14, 0, 14, size.height);
      canvas.drawRect(
        strip,
        Paint()
          ..shader = LinearGradient(
            begin: start,
            end: end,
            colors: [burnt.withValues(alpha: 0.18), Colors.transparent],
          ).createShader(strip),
      );
    }

    // Divider rule between items
    if (drawDivider) {
      final y = size.height - 1;
      canvas.drawLine(
        Offset(size.width * 0.12, y),
        Offset(size.width * 0.88, y),
        Paint()
          ..color = burnt.withValues(alpha: 0.22)
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
  }

  /// Jittered torn-edge silhouette along one side (the part OUTSIDE the
  /// paper, subtracted from the rect clip above).
  Path _tornEdge(Size size, Random rnd, {required bool left}) {
    final path = Path();
    final baseX = left ? 0.0 : size.width;
    final dir = left ? 1.0 : -1.0;
    path.moveTo(baseX, 0);
    var y = 0.0;
    while (y < size.height) {
      final step = 14 + rnd.nextDouble() * 18;
      y = min(y + step, size.height);
      path.lineTo(baseX + dir * rnd.nextDouble() * 5, y);
    }
    path.lineTo(baseX, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(ParchmentPainter oldDelegate) =>
      oldDelegate.brightness != brightness ||
      oldDelegate.tint != tint ||
      oldDelegate.seed != seed;
}
