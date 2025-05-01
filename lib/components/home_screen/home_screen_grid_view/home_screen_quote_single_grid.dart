import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/services/drift_service.dart';
import 'package:quotely_flutter_app/state_providers/favorite_quote_ids.dart';
import 'package:share_plus/share_plus.dart';

import 'home_screen_grid_content.dart';
import 'home_screen_grid_view_button.dart';

class HomeScreenQuoteSingleGrid extends ConsumerStatefulWidget {
  final double defaultHeight;
  final QuoteDto currentQuote;

  const HomeScreenQuoteSingleGrid({
    super.key,
    required this.defaultHeight,
    required this.currentQuote,
  });

  @override
  ConsumerState<HomeScreenQuoteSingleGrid> createState() =>
      _HomeScreenQuoteSingleGridState();
}

class _HomeScreenQuoteSingleGridState
    extends ConsumerState<HomeScreenQuoteSingleGrid>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final kPrimaryColor = Theme.of(context).primaryColor;
    final allFavoriteIds = ref.read(favoriteQuoteIdsProvider).toList();
    final selectedQuote = allFavoriteIds.contains(widget.currentQuote.id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          // height: widget.defaultHeight,
          // decoration: BoxDecoration(
          //   borderRadius: BorderRadius.circular(10),
          //   gradient: LinearGradient(
          //     colors: [
          //       kPrimaryColor.withValues(alpha: 0.4),
          //       kPrimaryColor.withValues(alpha: 0.3),
          //       kPrimaryColor.withValues(alpha: 0.2),
          //       kPrimaryColor.withValues(alpha: 0.1),
          //     ],
          //     begin: Alignment.topLeft,
          //     end: Alignment.bottomRight,
          //     stops: const [0.0, 0.3, 0.7, 1.0],
          //   ),
          height: widget.defaultHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                kPrimaryColor.withValues(alpha: 0.4),
                kPrimaryColor.withValues(alpha: 0.3),
                kPrimaryColor.withValues(alpha: 0.2),
                kPrimaryColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Stack(
            children: [
              HomeScreenGridViewButton(
                bottom: 5,
                right: 20,
                title: 'Share',
                iconData: Icons.share_outlined,
                onTap: () {
                  final shareText =
                      '"${widget.currentQuote.content}" - ${widget.currentQuote.author}\n\n'
                      'Shared via Quotely';
                  SharePlus.instance.share(
                    ShareParams(
                      text: shareText,
                      subject: 'Amazing quote by ${widget.currentQuote.author}',
                      sharePositionOrigin: Rect.fromPoints(
                        // This helps position the share dialog on iPad
                        Offset.zero,
                        const Offset(0, 0),
                      ),
                    ),
                  );
                },
              ),
              HomeScreenGridViewButton(
                bottom: 5,
                left: 20,
                title: 'Like',
                iconData: Icons.favorite_outline,
                isSelected: selectedQuote,
                onTap: () {
                  debugPrint(
                      "Making Quote with ID ${widget.currentQuote.id} as ${!selectedQuote}");
                  ref
                      .read(favoriteQuoteIdsProvider.notifier)
                      .addOrRemoveId(widget.currentQuote.id);
                  DriftService.changeQuoteUpdateStatus(
                    widget.currentQuote,
                    selectedQuote,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: HomeScreenGridContent(
                  quote: widget.currentQuote,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class HomeScreenQuoteSingleGridSkeletor extends StatelessWidget {
  final double defaultHeight;

  const HomeScreenQuoteSingleGridSkeletor({
    super.key,
    required this.defaultHeight,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: defaultHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
  }
}
