import 'package:flutter/material.dart';

import 'carousel_skeleton.dart';
import 'content_card.dart';
import 'content_item.dart';

/// A single full-height [ContentCard] for the "today" detail screens (Quote of
/// the Day, Fact of the Day, Daily Inspiration, etc.). Gives those screens the
/// same card as the main feed, sized to sit above the "See All" button in the
/// notification layout.
class SingleFeatureCard extends StatelessWidget {
  final ContentItem item;
  final ContentActions actions;

  const SingleFeatureCard({
    super.key,
    required this.item,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: ContentCard(item: item, actions: actions),
    );
  }
}

/// Loading placeholder matching [SingleFeatureCard]'s footprint.
class SingleFeatureCardSkeleton extends StatelessWidget {
  const SingleFeatureCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: const CarouselSkeletonCard(),
    );
  }
}
