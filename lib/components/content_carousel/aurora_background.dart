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

  // Green → turquoise → cyan.
  static const _green = Color(0xFF2ECC71);
  static const _turquoise = Color(0xFF1ABC9C);
  static const _cyan = Color(0xFF00BCD4);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alpha = widget.isDark ? 0.26 : 0.18;
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
              _cyan.withValues(alpha: alpha),
            ),
            _blob(
              Alignment.lerp(
                const Alignment(1.0, -0.5),
                const Alignment(0.4, 0.2),
                t,
              )!,
              _green.withValues(alpha: alpha),
            ),
            _blob(
              Alignment.lerp(
                const Alignment(-0.4, 1.0),
                const Alignment(0.5, 0.5),
                t,
              )!,
              _turquoise.withValues(alpha: alpha),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(Alignment center, Color color) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: 0.95,
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
