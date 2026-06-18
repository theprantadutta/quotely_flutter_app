import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';

import '../../screens/author_detail_screen.dart';
import '../shared/pressable_scale.dart';
import 'gradient_ring_avatar.dart';

/// A premium author row: gradient-ring avatar + name + role, with a quote-count
/// pill and chevron on the right. Press-scales on tap and hero-transitions its
/// avatar into the author-detail screen.
class SingleAuthorView extends StatelessWidget {
  final int index;
  final AuthorDto author;

  const SingleAuthorView({
    super.key,
    required this.index,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: PressableScale(
        onTap: () =>
            context.push('${AuthorDetailScreen.kRouteName}/${author.slug}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              GradientRingAvatar(
                name: author.name,
                imageUrl: author.imageUrl,
                radius: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      author.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (author.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        author.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _QuoteCountPill(count: author.quoteCount, accent: accent),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteCountPill extends StatelessWidget {
  final int count;
  final Color accent;

  const _QuoteCountPill({required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_quote_rounded, size: 14, color: accent),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for [SingleAuthorView]; wrap in a Skeletonizer.
class SingleAuthorViewSkeletor extends StatelessWidget {
  const SingleAuthorViewSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 29, backgroundColor: Colors.grey.shade300),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Abraham Lincoln',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text('American President'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text('12'),
          ],
        ),
      ),
    );
  }
}
