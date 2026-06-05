import 'package:flutter/material.dart';

import 'content_view_mode.dart';
import 'view_mode_preview_painters.dart';

/// Bottom sheet with painted mini-previews of every view mode.
Future<void> showViewModeBottomSheet({
  required BuildContext context,
  required ContentViewMode current,
  required ValueChanged<ContentViewMode> onSelect,
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final isDark = theme.brightness == Brightness.dark;
      final paper = isDark ? const Color(0xFF3A352E) : const Color(0xFFF6F0E1);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'View style',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final mode in ContentViewMode.values)
                    _ModePreviewTile(
                      mode: mode,
                      selected: mode == current,
                      paper: paper,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onSelect(mode);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ModePreviewTile extends StatelessWidget {
  final ContentViewMode mode;
  final bool selected;
  final Color paper;
  final VoidCallback onTap;

  const _ModePreviewTile({
    required this.mode,
    required this.selected,
    required this.paper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.4),
          ),
          color: theme.colorScheme.surfaceContainerLow,
        ),
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: ViewModePreviewPainter(
                  mode: mode,
                  paper: paper,
                  accent: theme.colorScheme.primary,
                ),
                size: const Size(double.infinity, double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mode.icon,
                    size: 15,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
