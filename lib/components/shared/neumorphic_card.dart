import 'package:flutter/material.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/neumorphic/neumorphic_decorations.dart';

/// A neumorphic card widget for content containers
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool showBorder;
  final VoidCallback? onTap;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = NeumorphicDecoration.cardRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.showBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: NeumorphicDecoration.card(
        context,
        borderRadius: borderRadius,
        baseColor: color,
        showBorder: showBorder,
      ),
      child: child,
    );

    if (onTap != null) {
      card = _TappableNeumorphicCard(
        onTap: onTap!,
        borderRadius: borderRadius,
        color: color,
        showBorder: showBorder,
        padding: padding,
        margin: margin,
        child: child,
      );
    }

    return card;
  }
}

class _TappableNeumorphicCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final Color? color;
  final bool showBorder;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const _TappableNeumorphicCard({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    this.color,
    required this.showBorder,
    required this.padding,
    this.margin,
  });

  @override
  State<_TappableNeumorphicCard> createState() => _TappableNeumorphicCardState();
}

class _TappableNeumorphicCardState extends State<_TappableNeumorphicCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final baseColor = widget.color ?? colors.surfaceContainer;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isPressed ? colors.surfaceContainerHigh : baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.showBorder
                ? Border.all(
                    color: colors.outline.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: colors.shadowDark.withValues(alpha: isDark ? 0.3 : 0.2),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colors.shadowDark.withValues(alpha: isDark ? 0.6 : 0.35),
                      offset: const Offset(5, 5),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
                      offset: const Offset(-5, -5),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A neumorphic quote card with gradient overlay
class NeumorphicQuoteCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const NeumorphicQuoteCard({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.surfaceContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.7 : 0.4),
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.1 : 0.9),
            offset: const Offset(-8, -8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A neumorphic settings tile for settings screens
class NeumorphicSettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final bool showArrow;

  const NeumorphicSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.showArrow = true,
  });

  @override
  State<NeumorphicSettingsTile> createState() => _NeumorphicSettingsTileState();
}

class _NeumorphicSettingsTileState extends State<NeumorphicSettingsTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final iconColor = widget.iconColor ?? colors.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isPressed ? colors.surfaceContainerHigh : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: colors.shadowLight.withValues(alpha: isDark ? 0.05 : 0.6),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: NeumorphicDecoration.circular(
                context,
                isPressed: _isPressed,
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing widget or arrow
            if (widget.trailing != null)
              widget.trailing!
            else if (widget.showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: colors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
