import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Platform share glyph: iOS share-sheet arrow vs Android share nodes.
IconData get kShareIcon => defaultTargetPlatform == TargetPlatform.iOS
    ? Icons.ios_share_rounded
    : Icons.share_rounded;

/// Grows the tap area to at least 44×44 (48 on Android) without changing
/// how the child looks, per the hit-target rule.
class HitTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool button;

  const HitTarget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.button = true,
  });

  @override
  Widget build(BuildContext context) {
    final min = defaultTargetPlatform == TargetPlatform.android ? 48.0 : 44.0;
    return Semantics(
      button: button && onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: min, minHeight: min),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}

/// Scales to 0.97 while pressed (kept from the old `PressableScale`).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: AnimatedScale(
        scale: _pressed && !context.reduceMotion ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Bare 20px icon in a 42px hit area (search, back, more, share). Pass
/// [background] for the rare filled circle, e.g. over an image.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;
  final Color? background;
  final Color? foreground;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 42,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Tooltip(
      message: semanticLabel,
      excludeFromSemantics: true,
      child: HitTarget(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background ?? Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: background == null ? 21 : 18,
            color: foreground ?? t.ink,
          ),
        ),
      ),
    );
  }
}

/// Filled ink pill, 52 tall, paper text. [expand] makes it full width.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final IconData? icon;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final enabled = onPressed != null && !loading;
    final label = context.qt.button.copyWith(color: t.bg);
    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: t.bg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: t.bg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  this.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: label,
                ),
              ),
            ],
          );
    return Semantics(
      button: true,
      enabled: enabled,
      label: this.label,
      excludeSemantics: true,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled || loading ? 1 : 0.45,
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: t.ink,
              shape: const StadiumBorder(),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Outlined pill, 52 tall, hairline `line` border, `ink` text.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final IconData? icon;
  final double height;

  /// Filled `surf` variant with no border ("Rate the app").
  final bool filled;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.icon,
    this.height = 52,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onPressed,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: filled ? t.surf : Colors.transparent,
            shape: filled
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  )
                : StadiumBorder(
                    side: BorderSide(color: t.ink.withValues(alpha: 0.28)),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: t.ink),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.qt.buttonSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet text action ("Skip", "Not now", "Reset to defaults").
class QTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const QTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HitTarget(
      onTap: onPressed,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: context.qt.chip.copyWith(
            fontSize: 14,
            color: color ?? context.q.mute,
          ),
        ),
      ),
    );
  }
}

/// 44×26 switch (46×28 when [large]); `ink` on, `line` off, paper knob.
class QToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool large;
  final String? semanticLabel;

  const QToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.large = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final w = large ? 46.0 : 44.0;
    final h = large ? 28.0 : 26.0;
    final knob = large ? 22.0 : 20.0;
    final enabled = onChanged != null;
    final duration = context.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: HitTarget(
        button: false,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onChanged!(!value);
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: w,
            height: h,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? t.ink : t.line,
              borderRadius: BorderRadius.circular(h),
            ),
            child: AnimatedAlign(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knob,
                height: knob,
                decoration: BoxDecoration(
                  color: value ? t.bg : t.surf,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 20px radio: 1.5px `line` ring off, 6px `ink` ring on.
class QRadio extends StatelessWidget {
  final bool selected;

  const QRadio({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? t.bg : Colors.transparent,
        border: Border.all(
          color: selected ? t.ink : t.line,
          width: selected ? 6 : 1.5,
        ),
      ),
    );
  }
}

/// A full-width tappable radio row ("Wrong author").
class QRadioRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const QRadioRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              QRadio(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: context.qt.rowTitle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
