import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'q_controls.dart';

/// Quiet separator label ("8:00 AM · QUOTE OF THE DAY"), mono and uppercase.
class TimeDivider extends StatelessWidget {
  final String text;

  const TimeDivider(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Center(
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: context.qt.overline,
        ),
      ),
    );
  }
}

/// A notice in the flow: plain accent text with an arrow when tappable.
/// (Spotlight/Folio replace filled pills with text.)
class SystemPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;

  const SystemPill(this.text, {super.key, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final color = onTap == null ? t.mute : t.accInk;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.qt.chip.copyWith(color: color),
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 15, color: color),
        ],
      ],
    );
    return Center(
      child: onTap == null
          ? content
          : HitTarget(onTap: onTap, semanticLabel: text, child: content),
    );
  }
}

/// Small "NEW" marker, mono in the accent.
class NewBadge extends StatelessWidget {
  final String text;

  const NewBadge({super.key, this.text = 'NEW'});

  @override
  Widget build(BuildContext context) => Text(text, style: context.qt.badge);
}

/// Small accent label ("ANIME", "SAVED", "SPOILER SHIELD ON"), mono,
/// uppercase, no fill.
class SoftPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final double fontSize;
  final EdgeInsets padding;

  const SoftPill(
    this.text, {
    super.key,
    this.icon,
    this.onTap,
    this.fontSize = 11,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final pill = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: t.accInk),
            const SizedBox(width: 5),
          ],
          Text(
            text.toUpperCase(),
            maxLines: 1,
            style: context.qt.overline.copyWith(
              fontSize: fontSize,
              color: t.accInk,
              letterSpacing: fontSize * 0.12,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return HitTarget(onTap: onTap, semanticLabel: text, child: pill);
  }
}

/// Uppercase mono section header ("QUOTES", "THEME").
class SectionOverline extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  const SectionOverline(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(left: 2, bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(text.toUpperCase(), style: context.qt.overline),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// One option for [FilterChips] and the segmented controls.
class ChipOption<T> {
  final T value;
  final String label;
  const ChipOption(this.value, this.label);
}

/// Horizontally scrolling text tabs: the selected one is ink and medium,
/// the rest muted. No backgrounds (Folio's "text tabs replace chips").
class FilterChips<T> extends StatelessWidget {
  final List<ChipOption<T>> options;
  final bool Function(T value) isSelected;
  final ValueChanged<T> onSelected;
  final EdgeInsets padding;
  final ScrollController? controller;

  const FilterChips({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (context, i) {
          final o = options[i];
          return _TextTab(
            label: o.label,
            selected: isSelected(o.value),
            onTap: () => onSelected(o.value),
          );
        },
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TextTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: context.qt.chip.copyWith(
              fontSize: 14.5,
              color: selected ? t.ink : t.mute,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

/// Suggestion ("courage") in the ask sheet: a hairline-outlined word.
class SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SuggestionChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      label: 'Ask about $label',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.line),
          ),
          child: Text(label, style: context.qt.chip),
        ),
      ),
    );
  }
}

/// Wrap chip for the interests picker: hairline when off, ink when on.
class InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const InterestChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? t.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? t.ink : t.line),
          ),
          child: Text(
            label,
            style: context.qt.chip.copyWith(
              fontSize: 14,
              color: selected ? t.bg : t.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Equal-width text tabs with a thin ink underline that slides to the
/// selected one ("Quotes 24 · Scenes 11 · Facts 9", "Light / Dark / System").
///
/// [labelStyle] lets an option render in its own font (reading font).
class SegmentedPill<T> extends StatelessWidget {
  final List<ChipOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final TextStyle Function(T value, TextStyle base)? labelStyle;

  const SegmentedPill({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final index = options.indexWhere((o) => o.value == value).clamp(0, 99);
    final duration = context.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth / options.length;
        return SizedBox(
          height: 44,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: 1, color: t.line),
              ),
              AnimatedPositioned(
                duration: duration,
                curve: Curves.easeOutCubic,
                left: w * index + w * 0.2,
                width: w * 0.6,
                bottom: 0,
                height: 2,
                child: ColoredBox(color: t.ink),
              ),
              Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: Semantics(
                        selected: o.value == value,
                        button: true,
                        label: o.label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (o.value == value) return;
                            HapticFeedback.selectionClick();
                            onChanged(o.value);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              style: () {
                                final base = context.qt.chip.copyWith(
                                  fontSize: 14.5,
                                  fontWeight: o.value == value
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: o.value == value ? t.ink : t.mute,
                                );
                                return labelStyle?.call(o.value, base) ?? base;
                              }(),
                              child: Text(
                                o.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Header-sized text toggle ("Play · Browse"): selected ink, others muted.
class MiniSegmented<T> extends StatelessWidget {
  final List<ChipOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  const MiniSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          SizedBox(
            height: 44,
            child: _TextTab(
              label: options[i].label,
              selected: options[i].value == value,
              onTap: () {
                if (options[i].value != value) onChanged(options[i].value);
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// n segments, 3 tall. Done = ink, remaining = `line`.
class SegmentedProgress extends StatelessWidget {
  final int total;
  final int done;

  const SegmentedProgress({super.key, required this.total, required this.done});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      label: '$done of $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                decoration: BoxDecoration(
                  color: i < done ? t.ink : t.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Thin progress bar: `line` track, ink fill.
class QProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const QProgressBar({super.key, required this.value, this.height = 4});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: t.line)),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: t.ink,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
