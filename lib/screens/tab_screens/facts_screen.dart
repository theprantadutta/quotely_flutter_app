import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/content_carousel/content_item.dart';
import '../../components/content_carousel/content_mappers.dart';
import '../../components/content_carousel/vertical_content_carousel.dart';
import '../../components/facts_screen/facts_screen_filter_list.dart';
import '../../components/shared/something_went_wrong.dart';
import '../../components/shared/top_navigation_bar.dart';
import '../../dtos/ai_fact_dto.dart';
import '../../riverpods/all_facts_data_provider.dart';
import '../../service_locator/init_service_locators.dart';
import '../../state_providers/user_interests.dart';
import '../../util/pagination_seed.dart';

class FactsScreen extends ConsumerStatefulWidget {
  static const kRouteName = '/facts';

  const FactsScreen({super.key});

  @override
  ConsumerState<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends ConsumerState<FactsScreen> {
  int factPageNumber = 1;
  int factPageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  bool isLoadingMore = false;
  List<AiFactDto> aiFacts = [];

  List<String> allSelectedCategory = [];
  List<String> allSelectedProvider = [];

  /// Interests last used as the base filter — guards the interests listener
  /// against redundant refetches (see build()).
  List<String> _appliedInterests = const [];

  /// Set once the first interest-aware fetch has run; until then the listener
  /// must not act (the initial load owns the first fetch).
  bool _initialLoadDone = false;

  final analytics = getIt.get<FirebaseAnalytics>();

  late final ContentActions _contentActions;

  @override
  void initState() {
    super.initState();
    _contentActions = buildFactContentActions(
      onLastItemReached: _fetchFacts,
    );
    _loadInitialFacts();
  }

  /// First load: wait for saved interests so the very first fetch is already
  /// filtered correctly — avoids fetching unfiltered, then resetting and
  /// refetching (which flashed the skeleton and raced the loading guard).
  Future<void> _loadInitialFacts() async {
    await ref.read(userInterestsProvider.notifier).ready;
    if (!mounted) return;
    _appliedInterests = List.of(ref.read(userInterestsProvider));
    await _fetchFacts();
    _initialLoadDone = true;
  }

  Future<void> _fetchFacts() async {
    debugPrint('Fetching Ai Facts...');
    if (!hasMoreData || isLoadingMore) return;

    if (!mounted) return;

    // Analytics parity with the quotes screen
    if (factPageNumber > 1) {
      analytics.logEvent(
        name: 'facts_paginated',
        parameters: {'page_number': factPageNumber},
      );
    }

    setState(() {
      isLoadingMore = true;
      hasError = false;
    });

    try {
      // Base filter: when no chips are selected, fall back to the user's
      // saved interests. Tapping chips narrows within that base for the visit.
      final interests = ref.read(userInterestsProvider);
      final effectiveCategories = allSelectedCategory.isNotEmpty
          ? allSelectedCategory
          : interests;
      final newFacts = await ref.read(
        fetchAllFactsProvider(
          factPageNumber,
          factPageSize,
          effectiveCategories,
          allSelectedProvider,
          PaginationSeed.current,
        ).future,
      );
      setState(() {
        hasMoreData = newFacts.aiFacts.length == 10;
        factPageNumber++;
        aiFacts.addAll(newFacts.aiFacts);
        isLoadingMore = false;
      });
    } catch (e) {
      if (kDebugMode) print(e);
      if (mounted) {
        setState(() {
          hasError = true;
          isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch from the top when the user's interests actually change (e.g.
    // edited in Settings). Compare by CONTENT — Dart lists use reference
    // equality, so a plain `previous == next` would re-fire endlessly and the
    // screen would never settle. Track what we've applied so we act once.
    ref.listen(userInterestsProvider, (previous, next) {
      // The initial load owns the first fetch; ignore until it's done.
      if (!_initialLoadDone) return;
      if (listEquals(_appliedInterests, next)) return;
      _appliedInterests = List.of(next);
      // Chips override interests for the current visit, so only the base
      // (no chips selected) view needs to refetch when interests change.
      if (allSelectedCategory.isNotEmpty) return;
      setState(() {
        factPageNumber = 1;
        aiFacts = [];
        hasMoreData = true;
      });
      ref.invalidate(fetchAllFactsProvider);
      _fetchFacts();
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          children: [
            const TopNavigationBar(
              title: 'Facts',
              icon: Icons.lightbulb_rounded,
            ),
            FactsScreenFilterList(
              onSelectedCategoryChange: (category) async {
                setState(() {
                  if (allSelectedCategory.contains(category)) {
                    allSelectedCategory.remove(category);
                  } else {
                    allSelectedCategory.add(category);
                  }
                  factPageNumber = 1;
                  aiFacts = [];
                  hasMoreData = true;
                });
                ref.invalidate(fetchAllFactsProvider);
                await _fetchFacts();
              },
              allSelectedCategories: allSelectedCategory,
            ),
            // The carousel consumes vertical drags, so refresh lives in the
            // top bar instead of a RefreshIndicator.
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (hasError && aiFacts.isEmpty) {
      return Center(
        child: SomethingWentWrong(
          title: 'Failed to get Facts.',
          onRetryPressed: _fetchFacts,
        ),
      );
    }

    if (aiFacts.isEmpty && !isLoadingMore) {
      return SomethingWentWrong(
        title: 'No facts found.',
        onRetryPressed: () {
          setState(() {
            hasError = false;
            hasMoreData = true;
          });
          _fetchFacts();
        },
      );
    }

    return VerticalContentCarousel(
      items: [for (final fact in aiFacts) contentItemFromFact(fact)],
      actions: _contentActions,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
  }
}
