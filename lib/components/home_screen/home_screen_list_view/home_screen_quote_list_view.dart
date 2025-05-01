import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../services/drift_service.dart';
import '../../../state_providers/favorite_quote_ids.dart';
import 'home_screen_list_content.dart';
import 'home_screen_list_view_button.dart';

class HomeScreenQuoteListView extends ConsumerStatefulWidget {
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
  ConsumerState<HomeScreenQuoteListView> createState() =>
      _HomeScreenQuoteListViewState();
}

class _HomeScreenQuoteListViewState
    extends ConsumerState<HomeScreenQuoteListView> {
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
        final currentQuote = widget.quotes[index];
        final allFavoriteIds = ref.read(favoriteQuoteIdsProvider).toList();
        final selectedQuote = allFavoriteIds.contains(currentQuote.id);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.only(top: 10, bottom: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kPrimaryColor.withValues(alpha: 0.3),
                kPrimaryColor.withValues(alpha: 0.2),
                kPrimaryColor.withValues(alpha: 0.1),
                kPrimaryColor.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.1, 0.4, 0.9, 1.0],
            ),
            border: Border.all(
              color: kPrimaryColor.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              HomeScreenListContent(
                quote: currentQuote,
              ),
              Padding(
                padding: EdgeInsets.only(right: 8.0, top: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HomeScreenListViewButton(
                      title: 'Like',
                      iconData: Icons.favorite_outline,
                      isSelected: selectedQuote,
                      onTap: () {
                        debugPrint(
                            "Making Quote with ID ${currentQuote.id} as ${!selectedQuote}");
                        ref
                            .read(favoriteQuoteIdsProvider.notifier)
                            .addOrRemoveId(currentQuote.id);
                        DriftService.changeQuoteUpdateStatus(
                          currentQuote,
                          selectedQuote,
                        );
                      },
                    ),
                    SizedBox(width: 10),
                    HomeScreenListViewButton(
                      title: 'Share',
                      iconData: Icons.share_outlined,
                      isSelected: false,
                      onTap: () {
                        final shareText =
                            '"${currentQuote.content}" - ${currentQuote.author}\n\n'
                            'Shared via Quotely';
                        SharePlus.instance.share(
                          ShareParams(
                            text: shareText,
                            subject: 'Amazing quote by ${currentQuote.author}',
                            sharePositionOrigin: Rect.fromPoints(
                              // This helps position the share dialog on iPad
                              Offset.zero,
                              const Offset(0, 0),
                            ),
                          ),
                        );
                      },
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
                  kPrimaryColor.withValues(alpha: 0.3),
                  kPrimaryColor.withValues(alpha: 0.2),
                  kPrimaryColor.withValues(alpha: 0.1),
                  kPrimaryColor.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.1, 0.4, 0.9, 1.0],
              ),
              border: Border.all(
                color: kPrimaryColor.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
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
                        onTap: () {},
                        isSelected: false,
                      ),
                      SizedBox(width: 10),
                      HomeScreenListViewButton(
                        title: 'Like',
                        iconData: Icons.favorite_outline,
                        onTap: () {},
                        isSelected: false,
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
