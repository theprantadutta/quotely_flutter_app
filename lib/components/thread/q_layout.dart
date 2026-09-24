import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import 'q_controls.dart';
import 'q_pills.dart';

/// The thread column never stretches edge to edge on tablets.
const double kThreadMaxWidth = 560;

/// Centers [child] in a column at most [kThreadMaxWidth] wide.
class ThreadColumn extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ThreadColumn({
    super.key,
    required this.child,
    this.maxWidth = kThreadMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Tab-screen header: big title + `meta` subtitle, up to two trailing
/// circle buttons (or any [trailing] widget, e.g. a MiniSegmented).
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.qt.titleScreen),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: context.qt.meta),
                ],
              ],
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 0),
            actions[i],
          ],
        ],
      ),
    );
  }
}

/// Back circle + title for pushed screens. [trailing] is an optional
/// circle action (⋯ or share).
class PushHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  const PushHeader({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onTap:
                onBack ??
                () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title!, style: context.qt.titlePush),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: context.qt.meta),
                    ],
                  ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Scaffold for pushed screens: `bg`, SafeArea, [PushHeader], a centered
/// column capped at [kThreadMaxWidth], and an optional sticky [bottom].
class ThreadPage extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget body;
  final Widget? bottom;
  final bool showHeader;

  const ThreadPage({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.body,
    this.bottom,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.q.bg,
      body: SafeArea(
        bottom: bottom == null,
        child: ThreadColumn(
          child: Column(
            children: [
              if (showHeader)
                PushHeader(
                  title: title,
                  subtitle: subtitle,
                  trailing: trailing,
                ),
              Expanded(child: body),
              if (bottom != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: bottom!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded `surf` card with no border (separation comes from the surface).
class QCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  const QCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.q.surf,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

/// Rows in a `surf` container (radius 22) with hairlines between them.
class GroupedList extends StatelessWidget {
  final List<Widget> children;
  final Color? color;

  const GroupedList({super.key, required this.children, this.color});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, thickness: 1, color: t.line));
      rows.add(children[i]);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color ?? t.surf,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: rows),
    );
  }
}

/// A grouped-list row: title (+ NEW) and optional description, with a
/// trailing chevron, toggle, value or pill.
class GroupedRow extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final bool isNew;
  final bool chevron;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? descriptionColor;

  const GroupedRow({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.isNew = false,
    this.chevron = false,
    this.onTap,
    this.titleColor,
    this.descriptionColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      title,
                      style: context.qt.rowTitle.copyWith(color: titleColor),
                    ),
                    if (isNew) const NewBadge(),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.qt.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: descriptionColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          if (chevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: t.mute),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
