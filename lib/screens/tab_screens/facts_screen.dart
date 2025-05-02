import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/facts_screen/facts_screen_filter_list.dart';
import '../../components/facts_screen/single_fact.dart';
import '../../components/shared/something_went_wrong.dart';
import '../../components/shared/top_navigation_bar.dart';
import '../../dtos/ai_fact_dto.dart';
import '../../riverpods/all_facts_data_provider.dart';

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
  late ScrollController _scrollController;

  List<String> allSelectedCategory = [];
  List<String> allSelectedProvider = [];

  @override
  void initState() {
    super.initState();
    _fetchFacts();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        hasMoreData &&
        !isLoadingMore) {
      _fetchFacts();
    }
  }

  Future<void> _fetchFacts() async {
    debugPrint('Fetching Ai Facts...');
    if (!hasMoreData || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
      hasError = false;
    });

    try {
      final newFacts = await ref.read(fetchAllFactsProvider(
        factPageNumber,
        factPageSize,
        allSelectedCategory,
        allSelectedProvider,
      ).future);
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
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
        child: RefreshIndicator(
          onRefresh: () {
            factPageNumber = 1;
            aiFacts = [];
            ref.invalidate(fetchAllFactsProvider);
            return _fetchFacts();
          },
          child: Column(
            children: [
              const TopNavigationBar(title: 'Facts'),
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
                  });
                  ref.invalidate(fetchAllFactsProvider);
                  await _fetchFacts();
                },
                allSelectedCategories: allSelectedCategory,
              ),
              if (hasError)
                Expanded(
                  child: Center(
                    child: SomethingWentWrong(
                      title: 'Failed to get Facts.',
                      onRetryPressed: _fetchFacts,
                    ),
                  ),
                ),

              // Display skeleton loaders when there’s no error and no data
              if (!hasError && aiFacts.isEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return SingleFactSkeletor();
                    },
                  ),
                ),

              // Display the main content if there are aiFacts available
              if (!hasError && aiFacts.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: aiFacts.length,
                    itemBuilder: (context, index) {
                      return SingleFact(
                        aiFact: aiFacts[index],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
