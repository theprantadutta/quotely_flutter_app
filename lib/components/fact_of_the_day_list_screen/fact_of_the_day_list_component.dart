import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';

import '../../dtos/fact_of_the_day_dto.dart';
import '../../riverpods/all_fact_of_the_day_provider.dart';
import '../content_carousel/content_item.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/vertical_content_carousel.dart';

class FactOfTheDayListComponent extends ConsumerStatefulWidget {
  const FactOfTheDayListComponent({super.key});

  @override
  ConsumerState<FactOfTheDayListComponent> createState() =>
      _FactOfTheDayListComponentState();
}

class _FactOfTheDayListComponentState
    extends ConsumerState<FactOfTheDayListComponent> {
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool _loadingMore = false;
  List<FactOfTheDayDto> facts = [];

  late final ContentActions _actions = buildFactContentActions(
    onLastItemReached: _loadMore,
  );

  Future<void> _loadMore() async {
    if (!hasMoreData || _loadingMore) return;
    _loadingMore = true;
    setState(() => pageNumber++);
  }

  Widget _buildCarousel({required bool isLoadingMore}) {
    return VerticalContentCarousel(
      items: [for (final fact in facts) contentItemFromFactOfTheDay(fact)],
      actions: _actions,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final factProvider = ref.watch(
      fetchAllFactOfTheDayProvider(pageNumber, pageSize),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.87,
      width: double.infinity,
      child: factProvider.when(
        skipLoadingOnRefresh: false,
        data: (data) {
          final factsFromDb = data.factOfTheDayWithFacts;
          if (factsFromDb.length < pageSize) {
            hasMoreData = false;
          }
          for (var fact in factsFromDb) {
            if (!facts.any((n) => n.factId == fact.factId)) {
              facts.add(fact);
            }
          }
          _loadingMore = false;
          return _buildCarousel(isLoadingMore: false);
        },
        error: (error, stackTrace) => Center(
          child: SomethingWentWrong(
            onRetryPressed: () =>
                ref.refresh(fetchAllFactOfTheDayProvider(1, 10)),
          ),
        ),
        loading: () => _buildCarousel(isLoadingMore: true),
      ),
    );
  }
}
