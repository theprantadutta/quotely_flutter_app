import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'painted_content.dart';

/// Report + share buttons used by every painted view mode (favorite
/// affordances are mode-specific: ribbon / heart / wax seal).
class PaintedReportShareButtons extends StatelessWidget {
  final PaintedContent content;
  final PaintedContentActions actions;
  final Color color;
  final double size;

  const PaintedReportShareButtons({
    super.key,
    required this.content,
    required this.actions,
    required this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.flag_outlined, size: size, color: color),
          tooltip: 'Report',
          onPressed: () => actions.onReport(context, content),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.share_outlined, size: size, color: color),
          tooltip: 'Share',
          onPressed: () => actions.onShare(content),
        ),
      ],
    );
  }
}

/// Heart favorite button with the app's existing AnimatedSwitcher +
/// ScaleTransition feel (used by deck and coverflow modes).
class PaintedHeartFavorite extends ConsumerWidget {
  final PaintedContent content;
  final PaintedContentActions actions;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const PaintedHeartFavorite({
    super.key,
    required this.content,
    required this.actions,
    required this.activeColor,
    required this.inactiveColor,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = actions.isFavorite(ref, content);
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: () => actions.onFavoriteToggle(ref, content),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(isFavorite),
          size: size,
          color: isFavorite ? activeColor : inactiveColor,
        ),
      ),
    );
  }
}
