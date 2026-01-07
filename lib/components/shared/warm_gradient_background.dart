import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/gradients/app_gradients.dart';

/// A warm gradient background container that adapts to light/dark mode
/// Replaces DarkGradientBackground with cozy warm tones
class WarmGradientBackground extends StatelessWidget {
  final Widget child;
  final GradientVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool showShadow;

  const WarmGradientBackground({
    super.key,
    required this.child,
    this.variant = GradientVariant.primary,
    this.padding,
    this.borderRadius,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: _getGradient(context),
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  LinearGradient _getGradient(BuildContext context) {
    switch (variant) {
      case GradientVariant.primary:
        return AppGradients.warmPrimary(context);
      case GradientVariant.firelight:
        return AppGradients.firelight(context);
      case GradientVariant.sunset:
        return AppGradients.sunsetWarmth(context);
      case GradientVariant.card:
        return AppGradients.cardBackground(context);
      case GradientVariant.scaffold:
        return AppGradients.scaffoldBackground(context);
    }
  }
}

enum GradientVariant {
  primary,
  firelight,
  sunset,
  card,
  scaffold,
}

/// A scaffold with warm gradient background
class WarmGradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool extendBody;

  const WarmGradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.scaffoldBackground,
              colors.background,
              colors.surfaceContainerLow,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// A card with warm gradient background
class WarmGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showBorder;

  const WarmGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: AppGradients.cardBackground(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: colors.outline.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
            offset: const Offset(4, 4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.05 : 0.6),
            offset: const Offset(-4, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// A decorative header with gradient background
class WarmGradientHeader extends StatelessWidget {
  final String? title;
  final Widget? child;
  final double height;
  final bool showCurvedBottom;

  const WarmGradientHeader({
    super.key,
    this.title,
    this.child,
    this.height = 150,
    this.showCurvedBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: AppGradients.sunsetWarmth(context),
        borderRadius: showCurvedBottom
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: child ??
            Center(
              child: Text(
                title ?? '',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),
      ),
    );
  }
}
