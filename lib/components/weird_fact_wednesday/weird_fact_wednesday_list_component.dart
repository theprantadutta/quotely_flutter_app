import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dtos/weird_fact_wednesday_dto.dart';
import '../../riverpods/all_weird_fact_wednesday_provider.dart';
import '../../theme/colors/app_colors.dart';
import '../shared/neumorphic_notification_fact_card.dart';
import '../shared/something_went_wrong.dart';

class WeirdFactWednesdayListComponent extends ConsumerStatefulWidget {
  const WeirdFactWednesdayListComponent({super.key});

  @override
  ConsumerState<WeirdFactWednesdayListComponent> createState() =>
      _WeirdFactWednesdayListComponentState();
}

class _WeirdFactWednesdayListComponentState
    extends ConsumerState<WeirdFactWednesdayListComponent> {
  ScrollController factScrollController = ScrollController();
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  List<WeirdFactWednesdayDto> facts = [];

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
          await ref.refresh(
            fetchAllWeirdFactWednesdayProvider(pageNumber, pageSize).future,
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
      setState(() {
        pageNumber = 1;
        facts = [];
        hasMoreData = true;
        hasError = false;
      });
      await ref.refresh(
        fetchAllWeirdFactWednesdayProvider(pageNumber, pageSize).future,
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final factProvider = ref.watch(
      fetchAllWeirdFactWednesdayProvider(pageNumber, pageSize),
    );

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: _refreshFacts,
      child: factProvider.when(
        skipLoadingOnRefresh: false,
        data: (data) {
          final factsFromDb = data.weirdFactWednesdayWithFacts;
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: facts.length + (hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == facts.length) {
                return const NeumorphicFactListItemSkeleton();
              }
              final currentFact = facts[index];
              return NeumorphicFactListItem(
                index: index,
                category: currentFact.aiFactCategory,
                content: currentFact.content,
                factDate: currentFact.factDate,
              );
            },
          );
        },
        error: (error, stackTrace) => Center(
          child: SomethingWentWrong(
            title: 'Failed to load weird facts',
            onRetryPressed: () {
              ref.invalidate(fetchAllWeirdFactWednesdayProvider);
            },
          ),
        ),
        loading: () {
          if (facts.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10,
              itemBuilder: (context, index) =>
                  const NeumorphicFactListItemSkeleton(),
            );
          }
          return ListView.builder(
            controller: factScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: facts.length + 1,
            itemBuilder: (context, index) {
              if (index == facts.length) {
                return const NeumorphicFactListItemSkeleton();
              }
              final currentFact = facts[index];
              return NeumorphicFactListItem(
                index: index,
                category: currentFact.aiFactCategory,
                content: currentFact.content,
                factDate: currentFact.factDate,
              );
            },
          );
        },
      ),
    );
  }
}
