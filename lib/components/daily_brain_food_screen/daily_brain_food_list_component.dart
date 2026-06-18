import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';

import '../../dtos/daily_brain_food_dto.dart';
import '../../riverpods/all_daily_brain_food_provider.dart';
import '../content_carousel/content_item.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/vertical_content_carousel.dart';

class DailyBrainFoodListComponent extends ConsumerStatefulWidget {
  const DailyBrainFoodListComponent({super.key});

  @override
  ConsumerState<DailyBrainFoodListComponent> createState() =>
      _DailyBrainFoodListComponentState();
}

class _DailyBrainFoodListComponentState
    extends ConsumerState<DailyBrainFoodListComponent> {
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool _loadingMore = false;
  List<DailyBrainFoodDto> facts = [];

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
      items: [for (final fact in facts) contentItemFromDailyBrainFood(fact)],
      actions: _actions,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final factProvider = ref.watch(
      fetchAllDailyBrainFoodProvider(pageNumber, pageSize),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.87,
      width: double.infinity,
      child: factProvider.when(
        skipLoadingOnRefresh: false,
        data: (data) {
          final factsFromDb = data.dailyBrainFoodWithFacts;
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
                ref.refresh(fetchAllDailyBrainFoodProvider(1, 10)),
          ),
        ),
        loading: () => _buildCarousel(isLoadingMore: true),
      ),
    );
  }
}
