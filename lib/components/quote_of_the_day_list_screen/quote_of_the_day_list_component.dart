import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/quote_of_the_day_list_screen/single_quote_of_the_day.dart';
import 'package:quotely_flutter_app/dtos/quote_of_the_day_dto.dart';
import 'package:quotely_flutter_app/riverpods/all_quote_of_the_day_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class QuoteOfTheDayListComponent extends ConsumerStatefulWidget {
  const QuoteOfTheDayListComponent({super.key});

  @override
  ConsumerState<QuoteOfTheDayListComponent> createState() =>
      _QuoteOfTheDayListComponentState();
}

class _QuoteOfTheDayListComponentState
    extends ConsumerState<QuoteOfTheDayListComponent> {
  ScrollController quoteScrollController = ScrollController();
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  List<QuoteOfTheDayDto> quotes = [];

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
          final _ = await ref.refresh(
            fetchAllQuoteOfTheDayProvider(pageNumber, pageSize).future,
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
      final _ = await ref.refresh(
        fetchAllQuoteOfTheDayProvider(pageNumber, pageSize).future,
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
    final quoteProvider = ref.watch(
      fetchAllQuoteOfTheDayProvider(pageNumber, pageSize),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.87,
      width: MediaQuery.sizeOf(context).width,
      // margin: EdgeInsets.symmetric(vertical: 5),
      child: RefreshIndicator.adaptive(
        onRefresh: _refreshQuotes,
        child: quoteProvider.when(
          skipLoadingOnRefresh: false,
          data: (data) {
            final quotesFromDb = data.quoteOfTheDayWithQuotes;
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
              itemCount: quotes.length + (hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == quotes.length) {
                  return Skeletonizer(
                    child: const SingleQuoteOfTheDaySkeletor(),
                  );
                }
                final currentQuote = quotes[index];
                return SingleQuoteOfTheDay(
                  index: index,
                  author: currentQuote.author,
                  content: currentQuote.content,
                  quoteDate: currentQuote.quoteDate,
                );
              },
            );
          },
          error: (error, stackTrace) =>
              const Center(child: Text('Something Went Wrong')),
          loading: () {
            if (quotes.isEmpty) {
              return Skeletonizer(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) =>
                      const SingleQuoteOfTheDaySkeletor(),
                ),
              );
            }
            return ListView.builder(
              controller: quoteScrollController,
              itemCount: quotes.length + 1,
              itemBuilder: (context, index) {
                if (index == quotes.length) {
                  return Skeletonizer(
                    child: const SingleQuoteOfTheDaySkeletor(),
                  );
                }
                final currentQuote = quotes[index];
                return SingleQuoteOfTheDay(
                  index: index,
                  author: currentQuote.author,
                  content: currentQuote.content,
                  quoteDate: currentQuote.quoteDate,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
