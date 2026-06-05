import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/painted_content.dart';

/// The book mode's favorite affordance: a ribbon bookmark hanging over the
/// right page's top edge. Favorited = saturated crimson and longer; the
/// length/color animate over 200ms.
class RibbonBookmark extends ConsumerWidget {
  final PaintedContent content;
  final PaintedContentActions actions;

  const RibbonBookmark({
    super.key,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = actions.isFavorite(ref, content);
    return GestureDetector(
      onTap: () => actions.onFavoriteToggle(ref, content),
      child: Semantics(
        button: true,
        label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: isFavorite ? 1 : 0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          builder: (context, v, _) => CustomPaint(
            size: Size(26, 52 + 16 * v),
            painter: _RibbonPainter(activation: v),
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  /// 0 = not favorited (short, desaturated), 1 = favorited (long, crimson).
  final double activation;

  _RibbonPainter({required this.activation});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ribbon = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - 9) // notched tail
      ..lineTo(0, h)
      ..close();

    final crimson = Color.lerp(
      const Color(0xFF8A7A6A),
      const Color(0xFFB3232A),
      activation,
    )!;
    final crimsonDark = Color.lerp(
      const Color(0xFF6A5C4E),
      const Color(0xFF7E1418),
      activation,
    )!;

    canvas.drawShadow(ribbon, Colors.black.withValues(alpha: 0.5), 3, false);
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [crimson, crimsonDark],
        ).createShader(Offset.zero & size),
    );
    // Edge stitching detail
    canvas.drawPath(
      ribbon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = crimsonDark,
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) =>
      oldDelegate.activation != activation;
}
