import 'package:flutter/material.dart';
import '../colors/app_colors.dart';

/// Gradient definitions for the warm & cozy theme
/// All gradients adapt to light/dark mode

class AppGradients {
  AppGradients._();

  /// Primary warm gradient - amber to warm brown
  /// Use for main backgrounds and hero sections
  static LinearGradient warmPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 1.0],
      colors: isDark
          ? [
              colors.primary.withValues(alpha: 0.4),
              colors.secondary.withValues(alpha: 0.3),
            ]
          : [
              colors.primary.withValues(alpha: 0.3),
              colors.secondary.withValues(alpha: 0.2),
            ],
    );
  }

  /// Firelight gradient - golden amber glow
  /// Use for special highlight sections
  static LinearGradient firelight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.5, 1.0],
      colors: isDark
          ? [
              colors.accent.withValues(alpha: 0.15),
              colors.accentSecondary.withValues(alpha: 0.1),
              Colors.transparent,
            ]
          : [
              colors.accent.withValues(alpha: 0.2),
              colors.accentSecondary.withValues(alpha: 0.1),
              Colors.transparent,
            ],
    );
  }

  /// Sunset warmth gradient - for hero/feature sections
  static LinearGradient sunsetWarmth(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.4, 1.0],
      colors: isDark
          ? [
              colors.primary.withValues(alpha: 0.25),
              colors.accent.withValues(alpha: 0.15),
              colors.secondary.withValues(alpha: 0.1),
            ]
          : [
              colors.primary.withValues(alpha: 0.15),
              colors.accent.withValues(alpha: 0.1),
              colors.secondary.withValues(alpha: 0.08),
            ],
    );
  }

  /// Card background gradient - subtle warmth
  static LinearGradient cardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.1, 0.9],
      colors: [
        colors.surface,
        colors.surfaceContainer,
      ],
    );
  }

  /// Accent button gradient - for primary CTAs
  static LinearGradient accentButton(BuildContext context) {
    final colors = AppColors.light; // Use light colors for consistent button appearance

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 1.0],
      colors: [
        colors.primary,
        colors.accentSecondary,
      ],
    );
  }

  /// Disabled button gradient
  static LinearGradient disabledButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.surfaceContainer,
        colors.surfaceContainerHigh,
      ],
    );
  }

  /// Quote card overlay gradient - for text readability
  static LinearGradient quoteCardOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.3, 0.7, 1.0],
      colors: [
        Colors.transparent,
        colors.surface.withValues(alpha: 0.1),
        colors.surface.withValues(alpha: 0.3),
        colors.surface.withValues(alpha: 0.6),
      ],
    );
  }

  /// Scaffold background gradient - subtle ambient warmth
  static LinearGradient scaffoldBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.3, 1.0],
      colors: [
        colors.scaffoldBackground,
        colors.background,
        colors.surfaceContainerLow,
      ],
    );
  }

  /// Header gradient - for app bars and headers
  static LinearGradient header(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.primary,
        colors.primaryDark,
      ],
    );
  }

  /// Onboarding page gradients - different warm tones per page
  static LinearGradient onboardingPage(BuildContext context, int pageIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    final gradientConfigs = [
      // Page 1 - Sunrise amber
      [colors.accent.withValues(alpha: 0.3), colors.primary.withValues(alpha: 0.2)],
      // Page 2 - Warm caramel
      [colors.primary.withValues(alpha: 0.25), colors.secondary.withValues(alpha: 0.15)],
      // Page 3 - Golden hour
      [colors.accentSecondary.withValues(alpha: 0.25), colors.accent.withValues(alpha: 0.2)],
    ];

    final configIndex = pageIndex.clamp(0, gradientConfigs.length - 1);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientConfigs[configIndex],
    );
  }

  /// Shimmer gradient - for loading states
  static LinearGradient shimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        colors.surfaceContainer,
        colors.surface,
        colors.surfaceContainer,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Bottom navigation gradient overlay
  static LinearGradient bottomNavOverlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        colors.scaffoldBackground.withValues(alpha: 0.8),
        colors.scaffoldBackground,
      ],
      stops: const [0.0, 0.3, 1.0],
    );
  }
}

/// Extension for easy gradient application
extension GradientDecoration on LinearGradient {
  BoxDecoration toBoxDecoration({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      gradient: this,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      border: border,
    );
  }
}
