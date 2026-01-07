import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/neumorphic/neumorphic_decorations.dart';

/// A neumorphic container widget with soft 3D effects
/// Supports convex (raised), concave (pressed), and flat styles
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final NeumorphicStyle style;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool isCircular;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.style = NeumorphicStyle.convex,
    this.width,
    this.height,
    this.borderRadius = NeumorphicDecoration.defaultRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = _getDecoration(context);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }

  BoxDecoration _getDecoration(BuildContext context) {
    if (isCircular) {
      return NeumorphicDecoration.circular(
        context,
        baseColor: color,
        isPressed: style == NeumorphicStyle.concave,
      );
    }

    switch (style) {
      case NeumorphicStyle.convex:
        return NeumorphicDecoration.convex(
          context,
          borderRadius: borderRadius,
          baseColor: color,
        );
      case NeumorphicStyle.concave:
        return NeumorphicDecoration.concave(
          context,
          borderRadius: borderRadius,
          baseColor: color,
        );
      case NeumorphicStyle.flat:
        return NeumorphicDecoration.flat(
          context,
          borderRadius: borderRadius,
          baseColor: color,
        );
    }
  }
}

/// An animated neumorphic container that transitions between styles
class AnimatedNeumorphicContainer extends StatelessWidget {
  final Widget child;
  final bool isPressed;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Duration duration;
  final Curve curve;

  const AnimatedNeumorphicContainer({
    super.key,
    required this.child,
    this.isPressed = false,
    this.width,
    this.height,
    this.borderRadius = NeumorphicDecoration.defaultRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final baseColor = color ?? colors.surface;

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                // Pressed/concave shadows
                BoxShadow(
                  color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.3),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: colors.shadowLight.withValues(alpha: isDark ? 0.05 : 0.5),
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                  spreadRadius: -2,
                ),
              ]
            : [
                // Raised/convex shadows
                BoxShadow(
                  color: colors.shadowDark.withValues(alpha: isDark ? 0.8 : 0.5),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: colors.shadowLight.withValues(alpha: isDark ? 0.1 : 0.8),
                  offset: const Offset(-6, -6),
                  blurRadius: 12,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// A circular neumorphic container for avatars and icons
class NeumorphicCircle extends StatelessWidget {
  final Widget child;
  final double size;
  final bool isPressed;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const NeumorphicCircle({
    super.key,
    required this.child,
    this.size = 48,
    this.isPressed = false,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: NeumorphicDecoration.circular(
        context,
        baseColor: color,
        isPressed: isPressed,
      ),
      child: Center(child: child),
    );
  }
}
