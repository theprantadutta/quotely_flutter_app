import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/fact_of_the_day_list_screen/single_fact_of_the_day.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../dtos/daily_brain_food_dto.dart';
import '../../riverpods/all_daily_brain_food_provider.dart';

class DailyBrainFoodListComponent extends ConsumerStatefulWidget {
  const DailyBrainFoodListComponent({super.key});

  @override
  ConsumerState<DailyBrainFoodListComponent> createState() =>
      _DailyBrainFoodListComponentState();
}

class _DailyBrainFoodListComponentState
    extends ConsumerState<DailyBrainFoodListComponent> {
  ScrollController factScrollController = ScrollController();
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  List<DailyBrainFoodDto> facts = [];

  @override
  void initState() {
    super.initState();
    factScrollController.addListener(_factScrollListener);
  }

  Future<void> _factScrollListener() async {
    if (factScrollController.position.pixels ==
        factScrollController.position.maxScrollExtent) {
      try {
        if (hasMoreData) {
          setState(() {
            hasError = false;
            pageNumber++;
          });
          final _ = await ref.refresh(
            fetchAllDailyBrainFoodProvider(
              pageNumber,
              pageSize,
            ).future,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        setState(() => hasError = true);
      }
    }
  }

  @override
  void dispose() {
    factScrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshFacts() async {
    debugPrint('Refreshing Facts...');
    try {
      final _ = await ref.refresh(
        fetchAllDailyBrainFoodProvider(
          pageNumber,
          pageSize,
        ).future,
      );
      setState(() {
        pageNumber = 1;
        hasError = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      setState(() {
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final factProvider = ref.watch(
      fetchAllDailyBrainFoodProvider(pageNumber, pageSize),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.87,
      width: MediaQuery.sizeOf(context).width,
      // margin: EdgeInsets.symmetric(vertical: 5),
      child: RefreshIndicator.adaptive(
        onRefresh: _refreshFacts,
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
            return ListView.builder(
              controller: factScrollController,
              itemCount: facts.length + (hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == facts.length) {
                  return Skeletonizer(
                      child: const SingleFactOfTheDaySkeletor());
                }
                final currentFact = facts[index];
                return SingleFactOfTheDay(
                  category: currentFact.aiFactCategory,
                  content: currentFact.content,
                  factDate: currentFact.factDate,
                );
              },
            );
          },
          error: (error, stackTrace) => Center(
            child: SomethingWentWrong(
              onRetryPressed: () => ref.refresh(
                fetchAllDailyBrainFoodProvider(1, 10),
              ),
            ),
          ),
          loading: () {
            if (facts.isEmpty) {
              return Skeletonizer(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) =>
                      const SingleFactOfTheDaySkeletor(),
                ),
              );
            }
            return ListView.builder(
              controller: factScrollController,
              itemCount: facts.length + 1,
              itemBuilder: (context, index) {
                if (index == facts.length) {
                  return Skeletonizer(
                      child: const SingleFactOfTheDaySkeletor());
                }
                final currentFact = facts[index];
                return SingleFactOfTheDay(
                  category: currentFact.aiFactCategory,
                  content: currentFact.content,
                  factDate: currentFact.factDate,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
