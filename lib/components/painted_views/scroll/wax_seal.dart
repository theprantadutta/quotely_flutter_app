import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/painted_content.dart';

/// The scroll mode's favorite affordance: a painted wax seal that turns
/// crimson when favorited, with a 200ms pop matching the app's existing
/// favorite animation feel.
class WaxSeal extends ConsumerStatefulWidget {
  final PaintedContent content;
  final PaintedContentActions actions;
  final double size;

  const WaxSeal({
    super.key,
    required this.content,
    required this.actions,
    this.size = 44,
  });

  @override
  ConsumerState<WaxSeal> createState() => _WaxSealState();
}

class _WaxSealState extends ConsumerState<WaxSeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 1),
  ]).animate(_pop);

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.actions.isFavorite(ref, widget.content);
    return GestureDetector(
      onTap: () {
        _pop.forward(from: 0);
        widget.actions.onFavoriteToggle(ref, widget.content);
      },
      child: Semantics(
        button: true,
        label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        child: ScaleTransition(
          scale: _scale,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _WaxSealPainter(
              seed: widget.content.id.hashCode,
              isFavorite: isFavorite,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaxSealPainter extends CustomPainter {
  final int seed;
  final bool isFavorite;

  _WaxSealPainter({required this.seed, required this.isFavorite});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.width * 0.42;

    // Irregular wax blob: 14-point polar path with seeded radius jitter,
    // joined with quadratic curves for soft molten edges.
    final rnd = Random(seed);
    const points = 14;
    final radii = List.generate(
      points,
      (_) => baseRadius * (0.88 + rnd.nextDouble() * 0.24),
    );

    final blob = Path();
    for (var i = 0; i <= points; i++) {
      final angle = i / points * 2 * pi;
      final r = radii[i % points];
      final p = center + Offset(cos(angle) * r, sin(angle) * r);
      if (i == 0) {
        blob.moveTo(p.dx, p.dy);
      } else {
        final prevAngle = (i - 0.5) / points * 2 * pi;
        final prevR = (radii[(i - 1) % points] + r) / 2 * 1.06;
        final ctrl =
            center + Offset(cos(prevAngle) * prevR, sin(prevAngle) * prevR);
        blob.quadraticBezierTo(ctrl.dx, ctrl.dy, p.dx, p.dy);
      }
    }
    blob.close();

    final waxCenter = isFavorite
        ? const Color(0xFFB3232A)
        : const Color(0xFF8A7A6A);
    final waxRim = isFavorite
        ? const Color(0xFF7E1418)
        : const Color(0xFF6A5C4E);

    canvas.drawShadow(blob, Colors.black, 3, false);
    canvas.drawPath(
      blob,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [waxCenter, waxRim],
        ).createShader(Rect.fromCircle(center: center, radius: baseRadius)),
    );

    // Embossed heart: dark "pressed" stroke with a white-alpha highlight
    // offset above it for the stamped-in illusion.
    final heart = _heartPath(center, size.width * 0.30);
    canvas.drawPath(
      heart.shift(const Offset(0, -1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    canvas.drawPath(
      heart,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Color.lerp(waxRim, Colors.black, 0.4)!,
    );
  }

  Path _heartPath(Offset center, double width) {
    final w = width;
    final top = center - Offset(0, w * 0.22);
    return Path()
      ..moveTo(top.dx, top.dy)
      ..cubicTo(
        top.dx - w * 0.55,
        top.dy - w * 0.45,
        top.dx - w * 0.75,
        top.dy + w * 0.30,
        top.dx,
        top.dy + w * 0.72,
      )
      ..cubicTo(
        top.dx + w * 0.75,
        top.dy + w * 0.30,
        top.dx + w * 0.55,
        top.dy - w * 0.45,
        top.dx,
        top.dy,
      );
  }

  @override
  bool shouldRepaint(_WaxSealPainter oldDelegate) =>
      oldDelegate.isFavorite != isFavorite || oldDelegate.seed != seed;
}
