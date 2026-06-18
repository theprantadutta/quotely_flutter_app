import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../authors_screen/gradient_ring_avatar.dart';
import '../content_carousel/aurora_background.dart';

/// Premium profile header for an author: a gradient-ring avatar over the app's
/// living aurora background, the name, role, and stat pills (quote count + when
/// they were added).
class AuthorProfileHeader extends StatelessWidget {
  final AuthorDto author;

  const AuthorProfileHeader({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
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
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradientRingAvatar(
                    name: author.name,
                    imageUrl: author.imageUrl,
                    radius: 52,
                    ringWidth: 4,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    author.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (author.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      author.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: accent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _StatPill(
                        icon: Icons.format_quote_rounded,
                        label: '${author.quoteCount} quotes',
                        accent: accent,
                        filled: true,
                      ),
                      _StatPill(
                        icon: Icons.calendar_today_rounded,
                        label:
                            'Since ${DateFormat.y().format(author.dateAdded)}',
                        accent: accent,
                      ),
                    ],
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

/// The author's biography in a clean, readable card.
class AuthorAboutCard extends StatelessWidget {
  final AuthorDto author;

  const AuthorAboutCard({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            author.bio,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Updated ${DateFormat.yMMMd().format(author.dateModified)}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool filled;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.accent,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: filled ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: filled
            ? null
            : Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
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

/// Loading placeholder for the profile header + about card; wrap in Skeletonizer.
class AuthorDetailAuthorBioSkeletor extends StatelessWidget {
  const AuthorDetailAuthorBioSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Skeletonizer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 52, backgroundColor: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Abraham Lincoln',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text('American President'),
                const SizedBox(height: 16),
                const Text('128 quotes   ·   Since 1809'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ABOUT'),
                SizedBox(height: 12),
                Text(
                  'American politician who served as the 16th president of the '
                  'United States from 1861 to 1865, leading the nation through '
                  'the Civil War.',
                  style: TextStyle(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
