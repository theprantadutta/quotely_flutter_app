import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aurora_background.dart';
import 'content_item.dart';
import 'text_fit.dart';

/// One full carousel card: eyebrow + heart up top, auto-sized body in the
/// middle over a large decorative quote glyph, author/tags + share/report
/// down below. Theme-native: surface tones with the same primary→green
/// gradient sweep the rest of the app uses.
class ContentCard extends ConsumerWidget {
  final ContentItem item;
  final ContentActions actions;

  const ContentCard({super.key, required this.item, required this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = theme.colorScheme.onSurface.withValues(alpha: 0.92);
    final faintInk = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final accent = isDark
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.85);
    final isQuote = item.type == ContentItemType.quote;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Living "aurora": soft green→cyan blobs that slowly drift behind
            // the content, giving each card a calm, breathing atmosphere.
            Positioned.fill(child: AuroraBackground(isDark: isDark)),
            // Large decorative quote glyph watermark, fully visible in the
            // top-left corner behind the content.
            Positioned(
              top: 10,
              left: 14,
              child: Text(
                '“',
                style: TextStyle(
                  fontSize: 120,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Body area: card minus the header (~44) and footer (~96)
                  final bodyBox = Size(
                    constraints.maxWidth,
                    constraints.maxHeight - 150,
                  );
                  final fontSize = fitFontSize(
                    text: item.body,
                    box: bodyBox,
                    baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
                    max: 26,
                    min: 14,
                  );
                  final bodyStyle = TextStyle(
                    fontSize: fontSize,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
                    color: ink,
                  );
                  final overflows = textOverflows(
                    text: item.body,
                    box: bodyBox,
                    style: bodyStyle,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: eyebrow label + heart
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (item.subtitle ?? (isQuote ? 'Quote' : 'Fact'))
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 2.4,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          _HeartButton(item: item, actions: actions),
                        ],
                      ),
                      // Body fills the middle of the card
                      Expanded(
                        child: overflows
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(item.body, style: bodyStyle),
                              )
                            : Center(child: Text(item.body, style: bodyStyle)),
                      ),
                      // Footer: author + tags on the left, actions right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.title != null)
                                  GestureDetector(
                                    onTap: actions.onTitleTap == null
                                        ? null
                                        : () => actions.onTitleTap!(
                                            context,
                                            item,
                                          ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 2.4,
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            item.title!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Tags only for quotes — a fact's category
                                // already shows as the eyebrow.
                                if (isQuote && item.tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final tag in item.tags.take(3))
                                          _TagChip(label: tag, color: accent),
                                        if (item.tags.length > 3)
                                          _TagChip(
                                            label: '+${item.tags.length - 3}',
                                            color: accent,
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // NOTE: deliberately no IconButton tooltips — their
                          // overlay timers crash when the hosting card
                          // animates away mid-swipe. Semantics covers a11y.
                          Semantics(
                            label: 'Report',
                            button: true,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.flag_outlined,
                                size: 19,
                                color: faintInk,
                              ),
                              onPressed: () => actions.onReport(context, item),
                            ),
                          ),
                          Semantics(
                            label: 'Share',
                            button: true,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.share_outlined,
                                size: 19,
                                color: faintInk,
                              ),
                              onPressed: () => actions.onShare(item),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated heart with the app's AnimatedSwitcher + ScaleTransition feel.
class _HeartButton extends ConsumerWidget {
  final ContentItem item;
  final ContentActions actions;

  const _HeartButton({required this.item, required this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = actions.isFavorite(ref, item);
    return Semantics(
      button: true,
      label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: () => actions.onFavoriteToggle(ref, item),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(isFavorite),
            size: 22,
            color: isFavorite
                ? Colors.redAccent
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
