import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dtos/quote_dto.dart';
import '../../../services/drift_quote_service.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/colors.dart';
import '../../../state_providers/favorite_quote_ids.dart';
import 'home_screen_grid_content.dart';

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
  void _handleShare() {
    final shareText =
        '"${widget.currentQuote.content}" - ${widget.currentQuote.author}\n\n'
        'Shared via Quotely';
    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Amazing quote by ${widget.currentQuote.author}',
        sharePositionOrigin: Rect.fromPoints(
          Offset.zero,
          const Offset(0, 0),
        ),
      ),
    );
  }

  void _toggleFavorite() async {
    final existingFavoriteQuoteIds = ref.read(favoriteQuoteIdsProvider);
    final newValue = !existingFavoriteQuoteIds.contains(widget.currentQuote.id);

    debugPrint("Making Quote with ID ${widget.currentQuote.id} as $newValue");
    final result = await DriftQuoteService.changeQuoteUpdateStatus(
        widget.currentQuote, newValue);
    ref
        .read(favoriteQuoteIdsProvider.notifier)
        .addOrUpdateViaStatus(widget.currentQuote.id, newValue);
    if (!result) {
      print('Error updating quote');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    final isCurrentFavorite =
        ref.watch(favoriteQuoteIdsProvider).contains(widget.currentQuote.id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Background with blur effect
          _buildBackground(theme.primaryColor, isDarkTheme),

          // Content with tags and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quote content
                Expanded(
                  child: HomeScreenGridContent(quote: widget.currentQuote),
                ),

                // Tags and actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTagsRow(context, isDarkTheme),
                    _buildActionsRow(context, isCurrentFavorite),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context, bool isDarkTheme) {
    final theme = Theme.of(context);
    return Expanded(
      flex: 8,
      child: SizedBox(
        height: 32, // Fixed height for the tags row
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: widget.currentQuote.tags.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final tag = widget.currentQuote.tags[index];
            return Chip(
              label: Text(
                tag,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
              side: BorderSide(
                color: theme.primaryColor.withValues(alpha: 0.05),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context, bool isCurrentFavorite) {
    return Expanded(
      flex: 3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isCurrentFavorite ? Icons.favorite : Icons.favorite_outline,
                    key: ValueKey(isCurrentFavorite),
                    size: 20,
                    color: isCurrentFavorite
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _handleShare,
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
    );
  }

  Widget _buildBackground(Color primaryColor, bool isDarkTheme) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        height: widget.defaultHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.1, 0.9],
            colors: [
              primaryColor.withValues(alpha: 0.1),
              kHelperColor.withValues(alpha: 0.1),
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
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Background with blur effect
          _buildBackground(theme.primaryColor, isDarkTheme),

          // Content with tags and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quote content
                Expanded(
                  child: HomeScreenGridContentSkeletor(),
                ),

                // Tags and actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTagsRow(context, isDarkTheme),
                    _buildActionsRow(context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color primaryColor, bool isDarkTheme) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        height: defaultHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _buildGradient(primaryColor, isDarkTheme),
        ),
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context, bool isDarkTheme) {
    final theme = Theme.of(context);
    return Flexible(
      child: Wrap(
        spacing: 8,
        children: ['Motivation']
            .map((tag) => Chip(
                  label: Text(
                    tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: theme.primaryColor.withValues(alpha: 0.05),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    return Expanded(
      flex: 3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  Icons.favorite_outline,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            Container(
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
          ],
        ),
      ),
    );
  }

  LinearGradient _buildGradient(Color primaryColor, bool isDarkTheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.1, 0.9],
      colors: [
        primaryColor.withValues(alpha: 0.1),
        kHelperColor.withValues(alpha: 0.1),
      ],
    );
  }
}
