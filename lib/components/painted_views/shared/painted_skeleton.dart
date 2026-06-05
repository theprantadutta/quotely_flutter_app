import 'package:flutter/material.dart';

import 'painted_card_style.dart';

enum PaintedSkeletonMode { scroll, card, page }

/// Initial-load placeholder for painted views: grey text bars pulsing on the
/// theme-native card chrome (skeletonizer can't shimmer canvas pixels, so
/// the placeholder is painted natively with a shared opacity pulse).
class PaintedSkeletonPane extends StatefulWidget {
  final PaintedSkeletonMode mode;

  const PaintedSkeletonPane({super.key, required this.mode});

  @override
  State<PaintedSkeletonPane> createState() => _PaintedSkeletonPaneState();
}

class _PaintedSkeletonPaneState extends State<PaintedSkeletonPane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = PaintedCardStyle.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (widget.mode) {
          case PaintedSkeletonMode.scroll:
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SizedBox(height: 150, child: _skeletonCard(style)),
              ),
            );
          case PaintedSkeletonMode.card:
          case PaintedSkeletonMode.page:
            return Center(
              child: SizedBox(
                width: constraints.maxWidth * 0.82,
                height: constraints.maxHeight * 0.72,
                child: _skeletonCard(style),
              ),
            );
        }
      },
    );
  }

  Widget _skeletonCard(PaintedCardStyle style) {
    return CustomPaint(painter: _SkeletonPainter(style: style, pulse: _pulse));
  }
}

class _SkeletonPainter extends CustomPainter {
  final PaintedCardStyle style;
  final Animation<double> pulse;

  _SkeletonPainter({required this.style, required this.pulse})
    : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    style.paintSurface(canvas, rrect, shadowBlur: 4);

    // Pulsing text bars
    final alpha = 0.45 + 0.30 * pulse.value;
    final barColor =
        (style.brightness == Brightness.dark ? Colors.white : Colors.black)
            .withValues(alpha: 0.10 * alpha + 0.04);
    final barPaint = Paint()..color = barColor;
    final widths = [1.0, 0.95, 0.98, 0.90, 0.60];
    final startY = size.height * 0.24;
    canvas.save();
    canvas.clipRRect(rrect);
    for (var i = 0; i < widths.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.10,
            startY + i * 22,
            size.width * 0.80 * widths[i],
            10,
          ),
          const Radius.circular(5),
        ),
        barPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkeletonPainter oldDelegate) =>
      oldDelegate.style != style;
}
