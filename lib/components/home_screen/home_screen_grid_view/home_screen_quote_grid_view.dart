import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/home_screen/home_screen_grid_view/home_screen_quote_single_grid.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../dtos/quote_dto.dart';

class HomeScreenQuoteGridView extends StatelessWidget {
  final List<QuoteDto> quotes;
  final int quotePageNumber;
  final Future Function() onLastItemScrolled;

  const HomeScreenQuoteGridView({
    super.key,
    required this.quotes,
    required this.quotePageNumber,
    required this.onLastItemScrolled,
  });

  @override
  Widget build(BuildContext context) {
    final defaultHeight = MediaQuery.sizeOf(context).height * 0.72;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: CarouselSlider.builder(
        options: CarouselOptions(
          padEnds: false,
          aspectRatio: 2.0,
          viewportFraction: 0.7,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
          height: defaultHeight,
          scrollDirection: Axis.vertical,
          onPageChanged: (index, reason) async {
            if (index == ((quotePageNumber - 1) * 10) - 4) {
              debugPrint('Time to Refetch...');
              await onLastItemScrolled();
            }
          },
        ),
        itemCount: quotes.length,
        itemBuilder: (
          BuildContext context,
          int itemIndex,
          int pageViewIndex,
        ) {
          final currentQuote = quotes[itemIndex];
          return HomeScreenQuoteSingleGrid(
            defaultHeight: defaultHeight,
            currentQuote: currentQuote,
          );
        },
      ),
    );
  }
}

class HomeScreenQuoteGridViewSkeltor extends StatelessWidget {
  const HomeScreenQuoteGridViewSkeltor({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultHeight = MediaQuery.sizeOf(context).height * 0.7;
    return Skeletonizer(
      child: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: CarouselSlider.builder(
          options: CarouselOptions(
            padEnds: false,
            aspectRatio: 2.0,
            viewportFraction: 0.7,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            height: defaultHeight,
            scrollDirection: Axis.vertical,
          ),
          itemCount: 15,
          itemBuilder: (
            BuildContext context,
            int itemIndex,
            int pageViewIndex,
          ) {
            return HomeScreenQuoteSingleGridSkeletor(
              defaultHeight: defaultHeight,
            );
          },
        ),
      ),
    );
  }
}
