import 'package:flutter/material.dart';
import '../colors/app_colors.dart';

/// Neumorphic design system decorations
/// Provides soft 3D effects with warm color palette

class NeumorphicDecoration {
  NeumorphicDecoration._();

  /// Default border radius for neumorphic elements
  static const double defaultRadius = 20.0;
  static const double buttonRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double chipRadius = 8.0;

  /// Shadow offset and blur values
  static const double shadowOffset = 6.0;
  static const double shadowBlur = 12.0;
  static const double shadowOffsetSmall = 3.0;
  static const double shadowBlurSmall = 6.0;

  /// Convex (raised) decoration - for buttons, cards
  static BoxDecoration convex(
    BuildContext context, {
    double borderRadius = defaultRadius,
    Color? baseColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final base = baseColor ?? colors.surface;

    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // Dark shadow (bottom-right) - depth
        BoxShadow(
          color: colors.shadowDark.withValues(alpha: isDark ? 0.8 : 0.5),
          offset: const Offset(shadowOffset, shadowOffset),
          blurRadius: shadowBlur,
          spreadRadius: 0,
        ),
        // Light shadow (top-left) - highlight
        BoxShadow(
          color: colors.shadowLight.withValues(alpha: isDark ? 0.1 : 0.8),
          offset: const Offset(-shadowOffset, -shadowOffset),
          blurRadius: shadowBlur,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Concave (pressed/inset) decoration - for active states, input fields
  static BoxDecoration concave(
    BuildContext context, {
    double borderRadius = defaultRadius,
    Color? baseColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final base = baseColor ?? colors.surface;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          base.withValues(alpha: 0.95),
          base,
        ],
      ),
      boxShadow: [
        // Inner dark shadow effect (simulated)
        BoxShadow(
          color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.3),
          offset: const Offset(shadowOffsetSmall, shadowOffsetSmall),
          blurRadius: shadowBlurSmall,
          spreadRadius: -2,
        ),
        // Inner light shadow effect (simulated)
        BoxShadow(
          color: colors.shadowLight.withValues(alpha: isDark ? 0.05 : 0.5),
          offset: const Offset(-shadowOffsetSmall, -shadowOffsetSmall),
          blurRadius: shadowBlurSmall,
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Flat decoration - for subtle containers
  static BoxDecoration flat(
    BuildContext context, {
    double borderRadius = defaultRadius,
    Color? baseColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final base = baseColor ?? colors.surface;

    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
          offset: const Offset(shadowOffsetSmall, shadowOffsetSmall),
          blurRadius: shadowBlurSmall,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: colors.shadowLight.withValues(alpha: isDark ? 0.05 : 0.6),
          offset: const Offset(-shadowOffsetSmall, -shadowOffsetSmall),
          blurRadius: shadowBlurSmall,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Circular neumorphic decoration - for avatars, icon buttons
  static BoxDecoration circular(
    BuildContext context, {
    Color? baseColor,
    bool isPressed = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final base = baseColor ?? colors.surface;

    if (isPressed) {
      return BoxDecoration(
        shape: BoxShape.circle,
        color: base,
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.3 : 0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      );
    }

    return BoxDecoration(
      shape: BoxShape.circle,
      color: base,
      boxShadow: [
        BoxShadow(
          color: colors.shadowDark.withValues(alpha: isDark ? 0.6 : 0.4),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
          offset: const Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Card decoration with border - for quote cards
  static BoxDecoration card(
    BuildContext context, {
    double borderRadius = cardRadius,
    Color? baseColor,
    bool showBorder = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final base = baseColor ?? colors.surfaceContainer;

    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(borderRadius),
      border: showBorder
          ? Border.all(
              color: colors.outline.withValues(alpha: 0.3),
              width: 1,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: colors.shadowDark.withValues(alpha: isDark ? 0.6 : 0.35),
          offset: const Offset(5, 5),
          blurRadius: 10,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
          offset: const Offset(-5, -5),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Button decoration with gradient accent
  static BoxDecoration accentButton(
    BuildContext context, {
    double borderRadius = buttonRadius,
    bool isPressed = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    if (isPressed) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryDark,
            colors.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      );
    }

    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.primary,
          colors.accentSecondary,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.4),
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.2),
          offset: const Offset(3, 3),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Inset input field decoration
  static BoxDecoration inputField(
    BuildContext context, {
    double borderRadius = buttonRadius,
    bool isFocused = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused
            ? colors.primary
            : colors.outline.withValues(alpha: 0.5),
        width: isFocused ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.shadowDark.withValues(alpha: isDark ? 0.3 : 0.15),
          offset: const Offset(2, 2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
      ],
    );
  }

  /// Chip/tag decoration
  static BoxDecoration chip(
    BuildContext context, {
    bool isSelected = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    if (isSelected) {
      return BoxDecoration(
        color: colors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(chipRadius),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      );
    }

    return BoxDecoration(
      color: colors.surfaceContainer,
      borderRadius: BorderRadius.circular(chipRadius),
      border: Border.all(
        color: colors.outlineVariant,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.shadowDark.withValues(alpha: isDark ? 0.3 : 0.15),
          offset: const Offset(2, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ],
    );
  }
}

/// Neumorphic style enum for widgets
enum NeumorphicStyle {
  convex,
  concave,
  flat,
}
