import 'package:flutter/material.dart';

import 'paper_texture.dart';

enum PaintedSkeletonMode { scroll, card, page }

/// Initial-load placeholder for painted views: grey text bars pulsing on the
/// mode's paper chrome (skeletonizer can't shimmer canvas pixels, so the
/// placeholder is painted natively with a shared opacity pulse).
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
    final theme = Theme.of(context);
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
                child: SizedBox(
                  height: 150,
                  child: _skeletonCard(theme),
                ),
              ),
            );
          case PaintedSkeletonMode.card:
          case PaintedSkeletonMode.page:
            return Center(
              child: SizedBox(
                width: constraints.maxWidth * 0.82,
                height: constraints.maxHeight * 0.72,
                child: _skeletonCard(theme),
              ),
            );
        }
      },
    );
  }

  Widget _skeletonCard(ThemeData theme) {
    return CustomPaint(
      painter: _SkeletonPainter(
        brightness: theme.brightness,
        tint: theme.primaryColor,
        pulse: _pulse,
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  final Brightness brightness;
  final Color tint;
  final Animation<double> pulse;

  _SkeletonPainter({
    required this.brightness,
    required this.tint,
    required this.pulse,
  }) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPicture(
      PaperTextureCache.of(size: size, brightness: brightness, tint: tint),
    );

    // Pulsing text bars
    final alpha = 0.45 + 0.30 * pulse.value;
    final barColor = (brightness == Brightness.dark
            ? Colors.white
            : Colors.black)
        .withValues(alpha: 0.10 * alpha + 0.04);
    final barPaint = Paint()..color = barColor;
    final widths = [1.0, 0.95, 0.98, 0.90, 0.60];
    final startY = size.height * 0.24;
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
      oldDelegate.brightness != brightness || oldDelegate.tint != tint;
}
