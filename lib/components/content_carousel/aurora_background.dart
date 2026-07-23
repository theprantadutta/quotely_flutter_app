import 'package:flutter/material.dart';

/// A slow, looping "aurora": three soft radial color blobs that drift behind
/// card content in a green → turquoise → cyan palette. No blur (the radial
/// falloff is soft enough), so it stays cheap even with several cards alive in
/// the carousel at once. Shared by the content card and its skeleton so the
/// loading state matches the loaded one.
class AuroraBackground extends StatefulWidget {
  final bool isDark;

  const AuroraBackground({super.key, required this.isDark});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  // Green → turquoise → cyan (dark mode keeps the original trio).
  static const _green = Color(0xFF2ECC71);
  static const _turquoise = Color(0xFF1ABC9C);
  static const _cyan = Color(0xFF00BCD4);

  // Light mode swaps the turquoise for a soft blue-violet: with three
  // same-hue greens the overlapping blobs blended into one flat mint wash;
  // a contrasting hue gives the aurora actual depth.
  static const _violet = Color(0xFF8B7CF6);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    // Light mode: smaller, unevenly weighted blobs so clean white surface
    // shows between them — brighter card, crisper text, real aurora feel.
    // Dark mode: unchanged big soft wash.
    final radius = isDark ? 0.95 : 0.62;
    final colors = isDark
        ? [
            _cyan.withValues(alpha: 0.26),
            _green.withValues(alpha: 0.26),
            _turquoise.withValues(alpha: 0.26),
          ]
        : [
            _cyan.withValues(alpha: 0.20),
            _green.withValues(alpha: 0.13),
            _violet.withValues(alpha: 0.12),
          ];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Stack(
          children: [
            _blob(
              Alignment.lerp(
                const Alignment(-0.9, -1.0),
                const Alignment(-0.2, -0.4),
                t,
              )!,
              colors[0],
              radius,
            ),
            _blob(
              Alignment.lerp(
                const Alignment(1.0, -0.5),
                const Alignment(0.4, 0.2),
                t,
              )!,
              colors[1],
              radius,
            ),
            _blob(
              Alignment.lerp(
                const Alignment(-0.4, 1.0),
                const Alignment(0.5, 0.5),
                t,
              )!,
              colors[2],
              radius,
            ),
          ],
        );
      },
    );
  }

  Widget _blob(Alignment center, Color color, double radius) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: radius,
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
