import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'q_controls.dart';

/// Centered "8:00 AM · Quote of the day" separator between thread groups.
class TimeDivider extends StatelessWidget {
  final String text;

  const TimeDivider(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.qt.meta.copyWith(fontSize: 12),
        ),
      ),
    );
  }
}

/// Centered `accSoft` pill: streaks, "tap to play" prompts, empty states.
class SystemPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;

  const SystemPill(this.text, {super.key, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.accSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: t.accInk),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: context.qt.label.copyWith(
                color: t.accInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    return Center(
      child: onTap == null
          ? pill
          : Semantics(
              button: true,
              child: Pressable(onTap: onTap, child: pill),
            ),
    );
  }
}

/// Small "NEW" marker after a row title or section overline.
class NewBadge extends StatelessWidget {
  final String text;

  const NewBadge({super.key, this.text = 'NEW'});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: t.accSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: context.qt.badge),
    );
  }
}

/// Compact `accSoft`/`accInk` pill ("Anime", "✓ Saved", "Spoiler shield on").
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
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final pill = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.accSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: t.accInk),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            maxLines: 1,
            style: context.qt.label.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: t.accInk,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return HitTarget(onTap: onTap, semanticLabel: text, child: pill);
  }
}

/// Uppercase section header ("QUOTES", "THEME", "ALL").
class SectionOverline extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  const SectionOverline(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(left: 4, bottom: 6),
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
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
  }
}

/// One option for [FilterChips].
class ChipOption<T> {
  final T value;
  final String label;
  const ChipOption(this.value, this.label);
}

/// Horizontally scrolling single-select pills. Selected = `ink` bg + `bg`
/// text; unselected = `surf` + `ink`.
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
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final o = options[i];
          final selected = isSelected(o.value);
          return Semantics(
            selected: selected,
            button: true,
            label: o.label,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(o.value);
              },
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? t.ink : t.surf,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    o.label,
                    style: context.qt.chip.copyWith(
                      color: selected ? t.bg : t.ink,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Outlined suggestion chip above the composer ("courage").
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.line),
          ),
          child: Text(label, style: context.qt.label.copyWith(color: t.ink)),
        ),
      ),
    );
  }
}

/// Wrap chip for the interests picker. Selected = `acc` + ✓.
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
          padding: EdgeInsets.fromLTRB(selected ? 12 : 14, 9, 14, 9),
          decoration: BoxDecoration(
            color: selected ? t.acc : t.surf,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? t.acc : t.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 14, color: t.onAcc),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: context.qt.chip.copyWith(
                    fontSize: 14,
                    color: selected ? t.onAcc : t.ink,
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

/// Equal-width pill switcher with an animated `acc` indicator
/// ("Quotes 24 · Scenes 11 · Facts 9", "Light / Dark / System").
///
/// [labelBuilder] lets an option render in its own font (reading font).
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
        : const Duration(milliseconds: 200);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surf,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.acc,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
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
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 40),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 4,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              style: () {
                                final base = context.qt.chip.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: o.value == value ? t.onAcc : t.ink,
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
          );
        },
      ),
    );
  }
}

/// Header-sized toggle (Thread/Cards, Play/Browse): selected = `ink` pill.
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
    final t = context.q;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surf,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            Semantics(
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minHeight: 34),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: o.value == value ? t.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    o.label,
                    style: context.qt.label.copyWith(
                      fontWeight: FontWeight.w800,
                      color: o.value == value ? t.bg : t.mute,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// n segments, 4 tall, 4 apart. Done = `acc`, remaining = `line`.
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
                height: 4,
                decoration: BoxDecoration(
                  color: i < done ? t.acc : t.line,
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

/// Thin rounded progress bar (Offline library): `line` track, `acc` fill.
class QProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const QProgressBar({super.key, required this.value, this.height = 8});

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
                  color: t.acc,
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
