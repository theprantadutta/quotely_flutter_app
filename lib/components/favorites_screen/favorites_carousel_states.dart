import 'package:flutter/material.dart';

import '../../constants/responsive.dart';
import '../content_carousel/carousel_skeleton.dart';

/// A single carousel-styled skeleton card, centred to match how the carousel
/// presents its own initial-load placeholder. Shared by the favorite quotes
/// and facts lists.
class FavoritesSkeletonCard extends StatelessWidget {
  const FavoritesSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const FractionallySizedBox(
      heightFactor: 0.82,
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: CarouselSkeletonCard(),
      ),
    );
  }
}

/// Friendly empty state shown when the user has no favorites yet.
class FavoritesEmptyState extends StatelessWidget {
  final String message;

  const FavoritesEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: cappedWidth(context, 0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty_outlined, size: 80),
            const SizedBox(height: 10),
            const Text(
              'No Favorites added yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
