import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../dtos/author_dto.dart';
import '../../screens/author_detail_screen.dart';
import '../content_carousel/aurora_background.dart';
import '../shared/pressable_scale.dart';
import 'gradient_ring_avatar.dart';

/// The hero "spotlight" card at the top of the Authors screen — the most-quoted
/// author among the loaded results, presented on the app's living aurora
/// background to make the screen feel premium and intentional.
class AuthorSpotlightCard extends StatelessWidget {
  final AuthorDto author;

  const AuthorSpotlightCard({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.85);

    return PressableScale(
      onTap: () =>
          context.push('${AuthorDetailScreen.kRouteName}/${author.slug}'),
      child: Container(
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
              Positioned.fill(child: AuroraBackground(isDark: isDark)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SPOTLIGHT',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2.4,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GradientRingAvatar(
                          name: author.name,
                          imageUrl: author.imageUrl,
                          radius: 38,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                author.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 22,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (author.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  author.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    color: accent,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _QuotePill(
                                count: author.quoteCount,
                                accent: accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuotePill extends StatelessWidget {
  final int count;
  final Color accent;

  const _QuotePill({required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_quote_rounded, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            '$count quotes',
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

/// Skeleton placeholder for [AuthorSpotlightCard]; wrap in a Skeletonizer.
class AuthorSpotlightCardSkeleton extends StatelessWidget {
  const AuthorSpotlightCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SPOTLIGHT',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(radius: 41, backgroundColor: Colors.grey.shade300),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Albert Einstein',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text('Theoretical Physicist'),
                    SizedBox(height: 12),
                    Text('128 quotes'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
