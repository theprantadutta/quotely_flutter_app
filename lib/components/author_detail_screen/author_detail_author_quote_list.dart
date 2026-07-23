import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:quotely_flutter_app/riverpods/all_quotes_by_author_provider.dart';
import 'package:quotely_flutter_app/util/pagination_seed.dart';

import '../../constants/responsive.dart';
import '../../dtos/quote_dto.dart';
import '../content_carousel/content_item.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/vertical_content_carousel.dart';
import '../shared/something_went_wrong.dart';

class AuthorDetailAuthorQuoteList extends ConsumerStatefulWidget {
  final AuthorDto author;

  /// When true the carousel fills whatever bounded space the parent gives it
  /// (tablet-landscape side-by-side layout) instead of a fixed height.
  final bool expand;

  const AuthorDetailAuthorQuoteList({
    super.key,
    required this.author,
    this.expand = false,
  });

  @override
  ConsumerState<AuthorDetailAuthorQuoteList> createState() =>
      _AuthorDetailAuthorQuoteListState();
}

class _AuthorDetailAuthorQuoteListState
    extends ConsumerState<AuthorDetailAuthorQuoteList> {
  int quotePageNumber = 1;
  int quotePageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  bool isLoadingMore = false;
  List<QuoteDto> quotes = [];

  late final ContentActions _contentActions;

  @override
  void initState() {
    super.initState();
    // Author tap disabled: we're already on this author's screen.
    _contentActions = buildQuoteContentActions(
      onLastItemReached: _fetchQuotes,
      enableAuthorTap: false,
    );
    _fetchQuotes();
  }

  Future<void> _fetchQuotes() async {
    debugPrint('Fetching Quotes...');
    if (!hasMoreData || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
      hasError = false;
    });

    try {
      final newQuotes = await ref.read(
        fetchAllQuotesByAuthorProvider(
          widget.author.slug,
          quotePageNumber,
          quotePageSize,
          PaginationSeed.current,
        ).future,
      );
      setState(() {
        hasMoreData = newQuotes.quotes.length == 10;
        quotePageNumber++;
        quotes.addAll(newQuotes.quotes);
        isLoadingMore = false;
      });
    } catch (e) {
      if (kDebugMode) print(e);
      if (mounted) {
        setState(() {
          hasError = true;
          isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasError && quotes.isEmpty) {
      return _stateBox(
        Center(
          child: SomethingWentWrong(
            title: 'Failed to get Quotes.',
            onRetryPressed: _fetchQuotes,
          ),
        ),
      );
    }

    if (!hasError && !isLoadingMore && quotes.isEmpty) {
      return _stateBox(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty_outlined, size: 80),
            const SizedBox(height: 10),
            Text(
              'No Quote Found by ${widget.author.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    // Same card carousel as the Home screen (it renders its own skeleton
    // while the first page loads).
    final carousel = VerticalContentCarousel(
      items: [for (final quote in quotes) contentItemFromQuote(quote)],
      actions: _contentActions,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
    if (widget.expand) return SizedBox.expand(child: carousel);
    // Capped so the embedded carousel can't balloon on tall tablets.
    return SizedBox(
      height: cappedHeight(context, 0.67, max: 640),
      child: carousel,
    );
  }

  Widget _stateBox(Widget child) {
    if (widget.expand) return SizedBox.expand(child: Center(child: child));
    return SizedBox(height: cappedHeight(context, 0.5, max: 420), child: child);
  }
}
