import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Opens a bottom sheet: paper `bg`, 24 top radius, drag handle, `scrim`
/// barrier. Keyboard-aware and capped at 90% of the screen.
Future<T?> showQSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useRootNavigator = true,
}) {
  final t = context.q;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    backgroundColor: t.bg,
    barrierColor: t.scrim,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: builder(context),
      ),
    ),
  );
}

/// Handle + optional title + content, with the sheet's standard padding.
class QSheetFrame extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool scrollable;

  const QSheetFrame({
    super.key,
    this.title,
    required this.child,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Semantics(
              header: true,
              child: Text(title!, style: context.qt.sectionTitle),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: t.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: scrollable ? SingleChildScrollView(child: body) : body,
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in an action sheet (Copy, Share as image, Save to collection…).
class SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final color = destructive ? Theme.of(context).colorScheme.error : t.ink;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: destructive ? color : t.mute),
              const SizedBox(width: 16),
              Text(
                label,
                style: context.qt.rowTitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
