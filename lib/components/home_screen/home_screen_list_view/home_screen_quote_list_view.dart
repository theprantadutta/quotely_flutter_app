import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../dtos/quote_dto.dart';
import 'home_screen_list_content.dart';
import 'home_screen_list_view_button.dart';

class HomeScreenQuoteListView extends StatelessWidget {
  final List<QuoteDto> quotes;

  const HomeScreenQuoteListView({
    super.key,
    required this.quotes,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Expanded(
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.only(top: 10, bottom: 5),
            decoration: BoxDecoration(
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
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                HomeScreenListContent(
                  quote: quotes[index],
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      HomeScreenListViewButton(
                        title: 'Share',
                        iconData: Icons.share_outlined,
                      ),
                      SizedBox(width: 10),
                      HomeScreenListViewButton(
                        title: 'Like',
                        iconData: Icons.favorite_outline,
                      ),
                    ],
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

class HomeScreenQuoteListViewSkeletor extends StatelessWidget {
  const HomeScreenQuoteListViewSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Expanded(
      child: Skeletonizer(
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.only(top: 10, bottom: 5),
              decoration: BoxDecoration(
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
                border: Border.all(
                  color: kPrimaryColor.withOpacity(0.1),
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  HomeScrenListContentSkeletor(),
                  Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        HomeScreenListViewButton(
                          title: 'Share',
                          iconData: Icons.share_outlined,
                        ),
                        SizedBox(width: 10),
                        HomeScreenListViewButton(
                          title: 'Like',
                          iconData: Icons.favorite_outline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
