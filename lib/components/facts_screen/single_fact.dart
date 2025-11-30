import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../constants/selectors.dart';
import '../../dtos/ai_fact_dto.dart';
import '../../services/drift_fact_service.dart';
import '../../state_providers/favorite_fact_ids.dart';
import 'report_fact_dialog.dart';

class SingleFact extends ConsumerWidget {
  final AiFactDto aiFact;

  const SingleFact({super.key, required this.aiFact});

  Future<void> toggleFavorite(WidgetRef ref) async {
    final existingFavoriteFactIds = ref.read(favoriteFactIdsProvider);
    final newValue = !existingFavoriteFactIds.contains(aiFact.id);
    debugPrint("Toggling favorite for quote ${aiFact.id} to $newValue");
    ref
        .read(favoriteFactIdsProvider.notifier)
        .addOrUpdateViaStatus(aiFact.id, newValue);
    await DriftFactService.changeFactFavoriteStatus(aiFact, newValue);
  }

  Future<void> shareFact() async {
    final shareText =
        '''
"${aiFact.content}"

Shared via Quotely
''';

    await Share.share(
      shareText,
      subject: 'Amazing fact from Quotely',
      sharePositionOrigin: const Rect.fromLTRB(0, 0, 0, 0),
    );
  }

  void _showReportFactDialog(BuildContext context, AiFactDto fact) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ReportFactDialog(fact: fact);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final favoriteList = ref.watch(favoriteFactIdsProvider);
    final isFavorite = favoriteList.contains(aiFact.id);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    aiFact.aiFactCategory,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Fact content
                Text(
                  aiFact.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _showReportFactDialog(context, aiFact),
                      icon: Icon(
                        Icons.flag_outlined, // Report icon
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      splashRadius: 20,
                    ),

                    // Share button
                    IconButton(
                      onPressed: shareFact,
                      icon: Icon(
                        Icons.share_rounded,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      splashRadius: 20,
                    ),

                    const SizedBox(width: 8),

                    // Favorite button with animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: IconButton(
                        key: ValueKey(isFavorite),
                        onPressed: () => toggleFavorite(ref),
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: isFavorite
                              ? primaryColor
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Decorative corner accent
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(30),
                ),
                color: theme.primaryColor.withValues(alpha: 0.1),
              ),
              child: Center(
                // child: Image.asset(
                //   'assets/quotely_icon.png',
                //   height: 20,
                //   width: 20,
                // ),
                child: Icon(
                  FontAwesomeIcons.quoteLeft,
                  size: 20,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SingleFactSkeletor extends StatelessWidget {
  const SingleFactSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return Skeletonizer(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Weird Laws',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fact content
                  Text(
                    'In Ohio, it\'s illegal to get a fish drunk',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Share button
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.share_rounded,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        splashRadius: 20,
                      ),

                      const SizedBox(width: 8),

                      // Favorite button
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.favorite_outline_rounded,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        splashRadius: 20,
                      ),

                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.flag_outlined,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Decorative corner accent
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(30),
                  ),
                  color: theme.primaryColor.withValues(alpha: 0.1),
                ),
                child: Center(
                  // child: Image.asset(
                  //   'assets/quotely_icon.png',
                  //   height: 20,
                  //   width: 20,
                  // ),
                  child: Icon(
                    FontAwesomeIcons.quoteLeft,
                    size: 20,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
