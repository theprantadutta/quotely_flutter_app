import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dtos/quote_dto.dart';
import '../../services/drift_quote_service.dart';
import '../../state_providers/favorite_quote_ids.dart';
import '../../theme/colors/app_colors.dart';
import 'swipeable_quote_card.dart';
import 'swipe_action_indicator.dart';

/// A stacked card layout for browsing quotes with swipe gestures
class QuoteCardStack extends ConsumerStatefulWidget {
  final List<QuoteDto> quotes;
  final VoidCallback onNeedMoreQuotes;
  final Function(QuoteDto quote)? onShare;
  final Function(QuoteDto quote)? onAuthorTap;

  const QuoteCardStack({
    super.key,
    required this.quotes,
    required this.onNeedMoreQuotes,
    this.onShare,
    this.onAuthorTap,
  });

  @override
  ConsumerState<QuoteCardStack> createState() => _QuoteCardStackState();
}

class _QuoteCardStackState extends ConsumerState<QuoteCardStack> {
  final CardSwiperController _controller = CardSwiperController();
  CardSwiperDirection? _swipeDirection;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    setState(() => _swipeDirection = null);

    // Favorite on right swipe
    if (direction == CardSwiperDirection.right && previousIndex < widget.quotes.length) {
      _toggleFavorite(widget.quotes[previousIndex]);
    }

    // Load more quotes when approaching the end
    if (currentIndex != null && currentIndex >= widget.quotes.length - 3) {
      widget.onNeedMoreQuotes();
    }
  }

  Future<void> _toggleFavorite(QuoteDto quote) async {
    HapticFeedback.mediumImpact();
    final favoriteIds = ref.read(favoriteQuoteIdsProvider);
    final isFavorite = favoriteIds.contains(quote.id);

    if (isFavorite) {
      await DriftQuoteService.changeQuoteUpdateStatus(quote, false);
      ref.read(favoriteQuoteIdsProvider.notifier).removeId(quote.id);
    } else {
      await DriftQuoteService.changeQuoteUpdateStatus(quote, true);
      ref.read(favoriteQuoteIdsProvider.notifier).addId(quote.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final favoriteIds = ref.watch(favoriteQuoteIdsProvider);

    if (widget.quotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Swipe indicators
        SwipeActionIndicator(
          direction: _swipeDirection,
          colors: colors,
        ),

        // Card stack
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: CardSwiper(
            controller: _controller,
            cardsCount: widget.quotes.length,
            numberOfCardsDisplayed: 3,
            backCardOffset: const Offset(0, -30),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            scale: 0.95,
            onSwipe: (previousIndex, currentIndex, direction) {
              _onSwipe(previousIndex, currentIndex, direction);
              return true;
            },
            onSwipeDirectionChange: (horizontalDirection, verticalDirection) {
              if (horizontalDirection == CardSwiperDirection.right) {
                setState(() => _swipeDirection = CardSwiperDirection.right);
              } else if (horizontalDirection == CardSwiperDirection.left) {
                setState(() => _swipeDirection = CardSwiperDirection.left);
              }
            },
            onEnd: () {
              // All cards swiped - request more
              widget.onNeedMoreQuotes();
            },
            cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
              if (index >= widget.quotes.length) return const SizedBox.shrink();

              final quote = widget.quotes[index];
              final isFavorite = favoriteIds.contains(quote.id);

              return SwipeableQuoteCard(
                quote: quote,
                isFavorite: isFavorite,
                onFavoriteToggle: () => _toggleFavorite(quote),
                onShare: () => widget.onShare?.call(quote),
                onAuthorTap: () => widget.onAuthorTap?.call(quote),
              );
            },
          ),
        ),

        // Bottom swipe hints
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: _SwipeHints(colors: colors),
        ),
      ],
    );
  }
}

class _SwipeHints extends StatelessWidget {
  final AppColorScheme colors;

  const _SwipeHints({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.chevron_left_rounded,
          size: 20,
          color: colors.textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'Skip',
          style: TextStyle(
            fontSize: 12,
            color: colors.textMuted.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 24),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: colors.textMuted.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 24),
        Text(
          'Favorite',
          style: TextStyle(
            fontSize: 12,
            color: colors.textMuted.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: colors.textMuted.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
