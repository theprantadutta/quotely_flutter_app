import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/facts_screen/facts_screen_filter_list.dart';
import '../../components/painted_views/shared/content_view_mode.dart';
import '../../components/painted_views/shared/painted_content.dart';
import '../../components/painted_views/shared/painted_content_mappers.dart';
import '../../components/painted_views/shared/painted_view_host.dart';
import '../../components/painted_views/shared/view_mode_button.dart';
import '../../components/shared/something_went_wrong.dart';
import '../../components/shared/top_navigation_bar.dart';
import '../../dtos/ai_fact_dto.dart';
import '../../main.dart';
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

  late final PaintedContentActions _paintedActions;

  @override
  void initState() {
    super.initState();
    _paintedActions = buildFactPaintedActions(
      onLastItemReached: _fetchFacts,
      onRefresh: _onRefresh,
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

  Future<void> _onRefresh() async {
    analytics.logEvent(name: 'facts_refreshed');
    setState(() {
      factPageNumber = 1;
      aiFacts = [];
      hasMoreData = true;
    });
    ref.invalidate(fetchAllFactsProvider);
    await _fetchFacts();
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = QuotelyApp.of(context).contentViewMode;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          children: [
            TopNavigationBar(
              title: 'Facts',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!viewMode.supportsPullToRefresh) ...[
                    ViewRefreshButton(onRefresh: _onRefresh),
                    const SizedBox(width: 8),
                  ],
                  ViewModeButton(
                    mode: viewMode,
                    // Screen setState required: QuotelyApp.of() is not an
                    // inherited dependency, so it won't rebuild us by itself.
                    onCycle: () =>
                        setState(QuotelyApp.of(context).cycleContentViewMode),
                    onSelect: (mode) => setState(
                      () => QuotelyApp.of(context).changeContentViewMode(mode),
                    ),
                  ),
                ],
              ),
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
            Expanded(
              child: viewMode.supportsPullToRefresh
                  ? RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: _buildContent(viewMode),
                    )
                  : _buildContent(viewMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ContentViewMode viewMode) {
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

    return PaintedViewHost(
      mode: viewMode,
      items: [for (final fact in aiFacts) paintedFromFact(fact)],
      actions: _paintedActions,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
  }
}
