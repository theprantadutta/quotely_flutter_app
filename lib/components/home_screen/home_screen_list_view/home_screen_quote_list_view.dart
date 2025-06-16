import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/selectors.dart';
import '../../../screens/author_detail_screen.dart';
import '../../../services/drift_quote_service.dart';
import '../../../state_providers/favorite_quote_ids.dart';

class HomeScreenQuoteListView extends ConsumerStatefulWidget {
  final List<QuoteDto> quotes;
  final Future<void> Function() onLastItemScrolled;
  final bool hasAlwaysScrollablePhysics;

  const HomeScreenQuoteListView({
    super.key,
    required this.quotes,
    required this.onLastItemScrolled,
    this.hasAlwaysScrollablePhysics = false,
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
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLastItemScrolled();
    }
  }

  // Future<void> _handleShare(QuoteDto quote) async {
  //   final shareText =
  //       '"${quote.content}" - ${quote.author}\n\nShared via Quotely';
  //   SharePlus.instance.share(
  //     ShareParams(
  //       text: shareText,
  //       subject: 'Amazing quote by ${quote.author}',
  //       sharePositionOrigin: Rect.fromPoints(
  //         Offset.zero,
  //         const Offset(0, 0),
  //       ),
  //     ),
  //   );
  // }

  Future<void> _handleShare(QuoteDto quote) async {
    final shareText = '''
"${quote.content}" - ${quote.author}

Shared via Quotely
''';

    await Share.share(
      shareText,
      subject: 'Amazing quote by ${quote.author}',
      sharePositionOrigin: const Rect.fromLTRB(0, 0, 0, 0),
    );
  }

  Future<void> _toggleFavorite(QuoteDto quote) async {
    final existingFavoriteQuoteIds = ref.read(favoriteQuoteIdsProvider);
    final newValue = !existingFavoriteQuoteIds.contains(quote.id);
    debugPrint("Toggling favorite for quote ${quote.id} to $newValue");
    ref
        .read(favoriteQuoteIdsProvider.notifier)
        .addOrUpdateViaStatus(quote.id, newValue);
    await DriftQuoteService.changeQuoteUpdateStatus(quote, newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authorColor = isDarkMode
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.8);
    final quoteColor = theme.colorScheme.onSurface.withValues(alpha: 0.9);
    return ListView.builder(
      physics: widget.hasAlwaysScrollablePhysics
          ? const AlwaysScrollableScrollPhysics()
          : null,
      controller: _scrollController,
      itemCount: widget.quotes.length,
      itemBuilder: (context, index) {
        final quote = widget.quotes[index];
        final isFavorite =
            ref.watch(favoriteQuoteIdsProvider).contains(quote.id);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: kGetDefaultGradient(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                right: 20,
                top: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quote content
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        quote.content,
                        style: TextStyle(
                          fontSize: _calculateFontSize(quote.content.length),
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                          color: quoteColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Author section
                    GestureDetector(
                      onTap: () => context.push(
                        '${AuthorDetailScreen.kRouteName}/${quote.authorSlug}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 2,
                              color: authorColor,
                              margin: const EdgeInsets.only(bottom: 6),
                            ),
                            Text(
                              '— ${quote.author}',
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: authorColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tags and actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 8,
                          child: SizedBox(
                            height: 32, // Fixed height for the tags row
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              itemCount: quote.tags.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final tag = quote.tags[index];
                                return Chip(
                                  label: Text(
                                    tag,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  backgroundColor:
                                      theme.primaryColor.withValues(alpha: 0.2),
                                  side: BorderSide(
                                    color: theme.primaryColor
                                        .withValues(alpha: 0.05),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                );
                              },
                            ),
                          ),
                        ),

                        // Action buttons
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleFavorite(quote),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        );
                                      },
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_outline,
                                        key: ValueKey(isFavorite),
                                        size: 20,
                                        color: isFavorite
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _handleShare(quote),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.share,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  double _calculateFontSize(int length) {
    const baseSize = 18.0;
    const maxReduction = 6.0;
    final reduction = (length / 100).clamp(0, maxReduction);
    return baseSize - reduction;
  }
}

class HomeScreenQuoteListViewSkeletor extends StatelessWidget {
  const HomeScreenQuoteListViewSkeletor({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authorColor = isDarkMode
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.8);
    final quoteColor = theme.colorScheme.onSurface.withValues(alpha: 0.9);
    return Skeletonizer(
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: kGetDefaultGradient(context),
            ),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  right: 20,
                  top: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quote content
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'No man can succeed in a line of endeavor which he does not like',
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                            color: quoteColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Author section
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 2,
                              color: authorColor,
                              margin: const EdgeInsets.only(bottom: 6),
                            ),
                            Text(
                              '— Napoleon Hill',
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: authorColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tags and actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tags
                          Flexible(
                            child: Wrap(
                              spacing: 8,
                              children: ['Motivation']
                                  .map((tag) => Chip(
                                        label: Text(
                                          tag,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        backgroundColor: theme.primaryColor
                                            .withValues(alpha: 0.2),
                                        side: BorderSide(
                                          color: theme.primaryColor
                                              .withValues(alpha: 0.05),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                          ),

                          // Action buttons
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                onPressed: () => {},
                                splashRadius: 20,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    Icons.favorite_border_outlined,
                                    size: 20,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                onPressed: () => {},
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ],
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
