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

  final analytics = getIt.get<FirebaseAnalytics>();

  late final ContentActions _contentActions;

  @override
  void initState() {
    super.initState();
    _contentActions = buildFactContentActions(
      onLastItemReached: _fetchFacts,
    );
    _fetchFacts();
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
      final newFacts = await ref.read(
        fetchAllFactsProvider(
          factPageNumber,
          factPageSize,
          allSelectedCategory,
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
