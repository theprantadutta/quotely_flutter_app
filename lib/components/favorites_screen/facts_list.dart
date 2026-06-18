import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/dtos/ai_fact_dto.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';
import 'package:quotely_flutter_app/services/drift_fact_service.dart';

import '../content_carousel/content_item.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/vertical_content_carousel.dart';
import 'favorites_carousel_states.dart';

/// Favorite facts, rendered with the same swipeable card carousel the Home
/// and Facts screens use — so favorites look and feel identical to the rest
/// of the app. Cards stream live from Drift, so un-hearting one here removes
/// it from the carousel immediately.
class FactsList extends StatefulWidget {
  const FactsList({super.key});

  @override
  State<FactsList> createState() => _FactsListState();
}

class _FactsListState extends State<FactsList> {
  final _analytics = getIt.get<FirebaseAnalytics>();

  // Favorites don't paginate — the whole favorite set streams from Drift.
  late final ContentActions _actions = buildFactContentActions(
    onLastItemReached: () async {},
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DriftFactService.watchAllFavoriteFacts([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FavoritesSkeletonCard();
        }
        if (snapshot.hasError) {
          _analytics.logEvent(
            name: 'favorites_facts_load_failed',
            parameters: {'error': snapshot.error.toString()},
          );
          return const Center(child: Text('Something went wrong'));
        }
        final facts = snapshot.data!;
        if (facts.isEmpty) {
          return const FavoritesEmptyState(
            message:
                'When you like a fact, it\'s going to show up here, this '
                'section helps you to read your Favorite facts over and over',
          );
        }
        return VerticalContentCarousel(
          items: [
            for (final fact in facts)
              contentItemFromFact(AiFactDto.fromDrift(fact)),
          ],
          actions: _actions,
          isLoadingMore: false,
          hasMoreData: false,
        );
      },
    );
  }
}
