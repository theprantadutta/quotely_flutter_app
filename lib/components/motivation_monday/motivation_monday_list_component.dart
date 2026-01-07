import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dtos/motivation_monday_dto.dart';
import '../../riverpods/all_motivation_monday_provider.dart';
import '../../theme/colors/app_colors.dart';
import '../shared/neumorphic_notification_quote_card.dart';
import '../shared/something_went_wrong.dart';

class MotivationMondayListComponent extends ConsumerStatefulWidget {
  const MotivationMondayListComponent({super.key});

  @override
  ConsumerState<MotivationMondayListComponent> createState() =>
      _MotivationMondayListComponentState();
}

class _MotivationMondayListComponentState
    extends ConsumerState<MotivationMondayListComponent> {
  ScrollController quoteScrollController = ScrollController();
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  List<MotivationMondayDto> quotes = [];

  @override
  void initState() {
    super.initState();
    quoteScrollController.addListener(_quoteScrollListener);
  }

  Future<void> _quoteScrollListener() async {
    if (quoteScrollController.position.pixels ==
        quoteScrollController.position.maxScrollExtent) {
      try {
        if (hasMoreData) {
          setState(() {
            hasError = false;
            pageNumber++;
          });
          await ref.refresh(
            fetchAllMotivationMondayProvider(pageNumber, pageSize).future,
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
    quoteScrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshQuotes() async {
    debugPrint('Refreshing Quotes...');
    try {
      setState(() {
        pageNumber = 1;
        quotes = [];
        hasMoreData = true;
        hasError = false;
      });
      await ref.refresh(
        fetchAllMotivationMondayProvider(pageNumber, pageSize).future,
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
    final quoteProvider = ref.watch(
      fetchAllMotivationMondayProvider(pageNumber, pageSize),
    );

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: _refreshQuotes,
      child: quoteProvider.when(
        skipLoadingOnRefresh: false,
        data: (data) {
          final quotesFromDb = data.motivationMondayWithQuotes;
          if (quotesFromDb.length < pageSize) {
            hasMoreData = false;
          }
          for (var quote in quotesFromDb) {
            if (!quotes.any((n) => n.quoteId == quote.quoteId)) {
              quotes.add(quote);
            }
          }
          return ListView.builder(
            controller: quoteScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: quotes.length + (hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == quotes.length) {
                return const NeumorphicQuoteListItemSkeleton();
              }
              final currentQuote = quotes[index];
              return NeumorphicQuoteListItem(
                index: index,
                author: currentQuote.author,
                content: currentQuote.content,
                quoteDate: currentQuote.quoteDate,
              );
            },
          );
        },
        error: (error, stackTrace) => Center(
          child: SomethingWentWrong(
            title: 'Failed to load motivations',
            onRetryPressed: () {
              ref.invalidate(fetchAllMotivationMondayProvider);
            },
          ),
        ),
        loading: () {
          if (quotes.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10,
              itemBuilder: (context, index) =>
                  const NeumorphicQuoteListItemSkeleton(),
            );
          }
          return ListView.builder(
            controller: quoteScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: quotes.length + 1,
            itemBuilder: (context, index) {
              if (index == quotes.length) {
                return const NeumorphicQuoteListItemSkeleton();
              }
              final currentQuote = quotes[index];
              return NeumorphicQuoteListItem(
                index: index,
                author: currentQuote.author,
                content: currentQuote.content,
                quoteDate: currentQuote.quoteDate,
              );
            },
          );
        },
      ),
    );
  }
}
