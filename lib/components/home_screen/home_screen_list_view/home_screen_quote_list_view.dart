import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../dtos/quote_dto.dart';
import 'home_screen_list_content.dart';
import 'home_screen_list_view_button.dart';

// class HomeScreenQuoteListView extends StatelessWidget {
//   final List<QuoteDto> quotes;

//   const HomeScreenQuoteListView({
//     super.key,
//     required this.quotes,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final kPrimaryColor = Theme.of(context).primaryColor;
//     return Expanded(
//       child: ListView.builder(
//         itemCount: 10,
//         itemBuilder: (context, index) {
//           return Container(
//             margin: const EdgeInsets.symmetric(vertical: 4),
//             padding: const EdgeInsets.only(top: 10, bottom: 5),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   kPrimaryColor.withOpacity(0.3),
//                   kPrimaryColor.withOpacity(0.2),
//                   kPrimaryColor.withOpacity(0.1),
//                   kPrimaryColor.withOpacity(0.4),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 stops: const [0.1, 0.4, 0.9, 1.0],
//               ),
//               border: Border.all(
//                 color: kPrimaryColor.withOpacity(0.1),
//               ),
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Column(
//               children: [
//                 HomeScreenListContent(
//                   quote: quotes[index],
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.only(right: 8.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       HomeScreenListViewButton(
//                         title: 'Share',
//                         iconData: Icons.share_outlined,
//                       ),
//                       SizedBox(width: 10),
//                       HomeScreenListViewButton(
//                         title: 'Like',
//                         iconData: Icons.favorite_outline,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

class HomeScreenQuoteListView extends StatefulWidget {
  final List<QuoteDto> quotes;
  final int quotePageNumber;
  final Future<void> Function() onLastItemScrolled;

  const HomeScreenQuoteListView({
    super.key,
    required this.quotes,
    required this.quotePageNumber,
    required this.onLastItemScrolled,
  });

  @override
  State<HomeScreenQuoteListView> createState() =>
      _HomeScreenQuoteListViewState();
}

class _HomeScreenQuoteListViewState extends State<HomeScreenQuoteListView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
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
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLastItemScrolled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.quotes.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
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
                quote: widget.quotes[index],
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HomeScreenListViewButton(
                      title: 'Like',
                      iconData: Icons.favorite_outline,
                    ),
                    SizedBox(width: 10),
                    HomeScreenListViewButton(
                      title: 'Share',
                      iconData: Icons.share_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeScreenQuoteListViewSkeletor extends StatelessWidget {
  const HomeScreenQuoteListViewSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Skeletonizer(
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
    );
  }
}
