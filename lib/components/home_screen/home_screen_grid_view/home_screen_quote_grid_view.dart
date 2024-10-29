import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../components/home_screen/home_screen_grid_view/home_screen_grid_content.dart';
import '../../../components/home_screen/home_screen_grid_view/home_screen_grid_view_button.dart';
import '../../../dtos/quote_dto.dart';

class HomeScreenQuoteGridView extends StatelessWidget {
  final List<QuoteDto> quotes;

  const HomeScreenQuoteGridView({
    super.key,
    required this.quotes,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    final defaultHeight = MediaQuery.sizeOf(context).height * 0.7;
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
        ),
        itemCount: quotes.length,
        itemBuilder: (
          BuildContext context,
          int itemIndex,
          int pageViewIndex,
        ) {
          return Container(
            height: defaultHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  kPrimaryColor.withOpacity(0.3),
                  kPrimaryColor.withOpacity(0.2),
                  kPrimaryColor.withOpacity(0.1),
                  kPrimaryColor.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.1, 0.4, 0.9, 1.0],
              ),
            ),
            child: Stack(
              children: [
                const HomeScreenGridViewButton(
                  bottom: 5,
                  right: 20,
                  title: 'Share',
                  iconData: Icons.share_outlined,
                ),
                const HomeScreenGridViewButton(
                  bottom: 5,
                  left: 20,
                  title: 'Like',
                  iconData: Icons.favorite_outline,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: HomeScreenGridContent(
                    quote: quotes[itemIndex],
                  ),
                ),
              ],
            ),
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
    final kPrimaryColor = Theme.of(context).primaryColor;
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
            return Container(
              height: defaultHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor.withOpacity(0.3),
                    kPrimaryColor.withOpacity(0.2),
                    kPrimaryColor.withOpacity(0.1),
                    kPrimaryColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.1, 0.4, 0.9, 1.0],
                ),
              ),
              child: const Stack(
                children: [
                  HomeScreenGridViewButton(
                    bottom: 5,
                    right: 20,
                    title: 'Share',
                    iconData: Icons.share_outlined,
                  ),
                  HomeScreenGridViewButton(
                    bottom: 5,
                    left: 20,
                    title: 'Like',
                    iconData: Icons.favorite_outline,
                  ),
                  HomeScreenGridContentSkeletor(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
