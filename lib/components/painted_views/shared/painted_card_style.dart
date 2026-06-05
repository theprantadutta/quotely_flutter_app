import 'package:flutter/material.dart';

import '../../../constants/colors.dart';

/// Theme-native visual language for all painted view modes: the same color
/// world as the rest of the app (surface tones + the primary→green gradient
/// the existing tiles use), soft rounded corners, subtle elevation.
/// No paper, no sepia, no frames.
class PaintedCardStyle {
  final Color surface;
  final Color gradientStart; // primary tint
  final Color gradientEnd; // helper-green tint
  final Color ink; // body text
  final Color accent; // author/category/highlights
  final Color faintInk; // secondary icons
  final Brightness brightness;

  PaintedCardStyle._({
    required this.surface,
    required this.gradientStart,
    required this.gradientEnd,
    required this.ink,
    required this.accent,
    required this.faintInk,
    required this.brightness,
  });

  factory PaintedCardStyle.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PaintedCardStyle._(
      surface: theme.colorScheme.surfaceContainerLow,
      // Matches kGetDefaultGradient's 10%-alpha primary→helper sweep
      gradientStart: theme.primaryColor.withValues(alpha: isDark ? 0.16 : 0.10),
      gradientEnd: kHelperColor.withValues(alpha: isDark ? 0.14 : 0.10),
      ink: theme.colorScheme.onSurface.withValues(alpha: 0.9),
      accent: isDark
          ? theme.colorScheme.secondary
          : theme.primaryColor.withValues(alpha: 0.8),
      faintInk: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      brightness: theme.brightness,
    );
  }

  /// Paints the standard card surface: surface base + gradient sweep +
  /// hairline top highlight, clipped to [rrect]. Cheap — no caching needed.
  void paintSurface(Canvas canvas, RRect rrect, {double shadowBlur = 8}) {
    final rect = rrect.outerRect;

    if (shadowBlur > 0) {
      canvas.drawShadow(
        Path()..addRRect(rrect),
        Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.9 : 0.45),
        shadowBlur,
        false,
      );
    }

    canvas.drawRRect(rrect, Paint()..color = surface);
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.1, 0.9],
          colors: [gradientStart, gradientEnd],
        ).createShader(rect),
    );

    // Hairline highlight along the top edge for a soft lift
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawLine(
      Offset(rect.left + 14, rect.top + 1),
      Offset(rect.right - 14, rect.top + 1),
      Paint()
        ..color = Colors.white.withValues(
          alpha: brightness == Brightness.dark ? 0.08 : 0.5,
        )
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }
}
