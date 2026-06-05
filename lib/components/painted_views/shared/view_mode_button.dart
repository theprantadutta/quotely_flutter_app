import 'package:flutter/material.dart';

import 'content_view_mode.dart';
import 'view_mode_bottom_sheet.dart';

/// Top-bar view-mode control: shows the current mode's icon; tap cycles to
/// the next mode, long-press opens the preview bottom sheet.
class ViewModeButton extends StatelessWidget {
  final ContentViewMode mode;
  final VoidCallback onCycle;
  final ValueChanged<ContentViewMode> onSelect;

  const ViewModeButton({
    super.key,
    required this.mode,
    required this.onCycle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // NOTE: no Tooltip here on purpose — Tooltip's default mobile trigger is
    // long-press, which would race our onLongPress (its overlay then outlives
    // the app-wide rebuild a mode change causes and crashes with "Looking up
    // a deactivated widget's ancestor is unsafe").
    return Semantics(
      button: true,
      label: '${mode.label} view — tap to switch, hold to pick',
      child: GestureDetector(
        onTap: onCycle,
        onLongPress: () => showViewModeBottomSheet(
          context: context,
          current: mode,
          onSelect: onSelect,
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.primaryColor.withValues(alpha: 0.10),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween(begin: 0.85, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              mode.icon,
              key: ValueKey(mode),
              size: 22,
              color: theme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Explicit refresh affordance for modes without pull-to-refresh.
class ViewRefreshButton extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const ViewRefreshButton({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Refresh',
      child: GestureDetector(
        onTap: onRefresh,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.primaryColor.withValues(alpha: 0.10),
          ),
          child: Icon(Icons.refresh, size: 22, color: theme.primaryColor),
        ),
      ),
    );
  }
}
