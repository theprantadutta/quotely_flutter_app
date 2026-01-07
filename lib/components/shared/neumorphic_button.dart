import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/neumorphic/neumorphic_decorations.dart';

/// A neumorphic button with tactile press feedback
class NeumorphicButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final bool useGradient;
  final double? width;
  final EdgeInsetsGeometry padding;

  const NeumorphicButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.useGradient = false,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final isDisabled = !widget.isEnabled || widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          padding: widget.padding,
          decoration: widget.useGradient
              ? NeumorphicDecoration.accentButton(context, isPressed: _isPressed)
              : NeumorphicDecoration.convex(
                  context,
                  borderRadius: NeumorphicDecoration.buttonRadius,
                  baseColor: isDisabled
                      ? colors.surfaceContainer
                      : (_isPressed ? colors.surfaceContainerHigh : null),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.useGradient
                        ? colors.onPrimary
                        : colors.primary,
                  ),
                )
              else if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: isDisabled
                      ? colors.textMuted
                      : (widget.useGradient
                          ? colors.onPrimary
                          : colors.primary),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? colors.textMuted
                      : (widget.useGradient
                          ? colors.onPrimary
                          : colors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A neumorphic icon button with circular shape
class NeumorphicIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isEnabled;
  final String? tooltip;

  const NeumorphicIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconColor,
    this.backgroundColor,
    this.isEnabled = true,
    this.tooltip,
  });

  @override
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      setState(() => _isPressed = true);
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    Widget button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: NeumorphicDecoration.circular(
            context,
            baseColor: widget.backgroundColor,
            isPressed: _isPressed,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.size * 0.5,
              color: widget.isEnabled
                  ? (widget.iconColor ?? colors.primary)
                  : colors.textMuted,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// A neumorphic text button (no elevation, just color change)
class NeumorphicTextButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const NeumorphicTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  State<NeumorphicTextButton> createState() => _NeumorphicTextButtonState();
}

class _NeumorphicTextButtonState extends State<NeumorphicTextButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final textColor = widget.color ?? colors.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.7 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: textColor),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
