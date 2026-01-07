import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: deprecated_member_use
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/home_screen/home_screen_quote_filters.dart';
import '../../components/home_screen/quote_card_stack.dart';
import '../../components/shared/something_went_wrong.dart';
import '../../dtos/quote_dto.dart';
import '../../main.dart';
import '../../notifications/push_notification.dart';
import '../../riverpods/all_quote_data_provider.dart';
import '../../screens/author_detail_screen.dart';
import '../../screens/legal_content_screen.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/drift_fact_service.dart';
import '../../services/drift_quote_service.dart';
import '../../state_providers/favorite_fact_ids.dart';
import '../../state_providers/favorite_quote_ids.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/gradients/app_gradients.dart';
import '../../util/pagination_seed.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const kRouteName = '/home';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int quotePageNumber = 1;
  int quotePageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  bool isLoadingMore = false;
  List<QuoteDto> quotes = [];

  List<String> allSelectedTags = [];

  final analytics = getIt.get<FirebaseAnalytics>();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _fetchQuotes();
    addAllFavoriteIds();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndShowTermsDialog();
      await PushNotifications.asyncQueue.start();
    });
  }

  Future<void> _checkAndShowTermsDialog() async {
    const String termsKey = 'hasAcceptedTermsV2';
    final preferences = await SharedPreferences.getInstance();

    final bool hasAccepted = preferences.getBool(termsKey) ?? false;
    if (hasAccepted) return;

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    bool isChecked = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void openLegalScreen(String title, String filePath) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      LegalContentScreen(title: title, markdownFile: filePath),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Welcome to Quotely!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Before you begin, please review our policies. By continuing, you agree to our terms.',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                        children: [
                          const TextSpan(text: 'I have read and agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: colors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => openLegalScreen(
                                    'Terms & Conditions',
                                    'assets/legal/terms.md',
                                  ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: colors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => openLegalScreen(
                                    'Privacy & Policy',
                                    'assets/legal/privacy.md',
                                  ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setDialogState(() => isChecked = !isChecked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? colors.primary
                                    : colors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isChecked
                                      ? colors.primary
                                      : colors.outline,
                                  width: 2,
                                ),
                              ),
                              child: isChecked
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: colors.onPrimary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'I understand and accept.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                GestureDetector(
                  onTap: isChecked
                      ? () async {
                          HapticFeedback.lightImpact();
                          await preferences.setBool(termsKey, true);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        }
                      : () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please accept the terms and conditions.',
                                style: GoogleFonts.lora(),
                              ),
                              backgroundColor: colors.error,
                            ),
                          );
                        },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isChecked
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.primary,
                                colors.primaryDark,
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                colors.outline,
                                colors.outline,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isChecked
                          ? [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      'Continue to App',
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isChecked
                            ? colors.onPrimary
                            : colors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchQuotes() async {
    if (!hasMoreData || isLoadingMore) return;

    if (quotePageNumber > 1) {
      analytics.logEvent(
        name: 'quotes_paginated',
        parameters: {'page_number': quotePageNumber},
      );
    }

    setState(() {
      isLoadingMore = true;
      hasError = false;
    });

    try {
      final newQuotes = await ref.read(
        fetchAllQuotesProvider(
          quotePageNumber,
          quotePageSize,
          allSelectedTags,
          PaginationSeed.current,
        ).future,
      );
      setState(() {
        hasMoreData = newQuotes.quotes.length == quotePageSize;
        quotePageNumber++;
        quotes.addAll(newQuotes.quotes);
        isLoadingMore = false;
      });
    } catch (e) {
      if (kDebugMode) print(e);
      analytics.logEvent(
        name: 'quote_fetch_failed',
        parameters: {'page_number': quotePageNumber, 'error': e.toString()},
      );
      if (mounted) {
        setState(() {
          hasError = true;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> addAllFavoriteIds() async {
    final allFavoriteQuoteIds = await DriftQuoteService.getAllFavoriteQuoteIds();
    talker?.info('All Favorite QuoteIds: $allFavoriteQuoteIds');
    final allFavoriteFactIds = await DriftFactService.getAllFavoriteFactIds();
    talker?.info('All Favorite FactIds: $allFavoriteFactIds');
    ref.read(favoriteQuoteIdsProvider.notifier).addOrUpdateIdList(allFavoriteQuoteIds);
    ref.read(favoriteFactIdsProvider.notifier).addOrUpdateIdList(allFavoriteFactIds);
  }

  void _shareQuote(QuoteDto quote) {
    analytics.logEvent(
      name: 'quote_shared',
      parameters: {'quote_id': quote.id},
    );
    // ignore: deprecated_member_use
    Share.share(
      '"${quote.content}" — ${quote.author}\n\nShared via Quotely',
    );
  }

  void _goToAuthor(QuoteDto quote) {
    analytics.logEvent(
      name: 'author_viewed_from_card',
      parameters: {'author': quote.author},
    );
    context.push(AuthorDetailScreen.kRouteName, extra: quote.author);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.scaffoldBackground(context),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(colors),

            // Tag filters
            if (!hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: HomeScreenQuoteFilters(
                  allSelectedTags: allSelectedTags,
                  onSelectedTagChange: (String currentTag) async {
                    analytics.logEvent(
                      name: 'quote_filter_changed',
                      parameters: {
                        'toggled_tag': currentTag,
                        'all_selected_tags': allSelectedTags.join(','),
                      },
                    );
                    setState(() {
                      if (allSelectedTags.contains(currentTag)) {
                        allSelectedTags.remove(currentTag);
                      } else {
                        allSelectedTags.add(currentTag);
                      }
                      quotePageNumber = 1;
                      quotes = [];
                      hasMoreData = true;
                    });
                    ref.invalidate(fetchAllQuotesProvider);
                    await _fetchQuotes();
                  },
                ),
              ),

            // Main content - Stacked cards
            Expanded(
              child: _buildContent(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Logo and title
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.format_quote_rounded,
                color: colors.onPrimary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quotely',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              Text(
                'Swipe for wisdom',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Loading indicator
          if (isLoadingMore && quotes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(AppColorScheme colors) {
    // Error state
    if (hasError && quotes.isEmpty) {
      return Center(
        child: SomethingWentWrong(
          title: 'Failed to get Quotes.',
          onRetryPressed: () {
            setState(() {
              hasError = false;
              hasMoreData = true;
            });
            _fetchQuotes();
          },
        ),
      );
    }

    // Initial loading state
    if (quotes.isEmpty && isLoadingMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowDark.withValues(alpha: 0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading quotes...',
              style: GoogleFonts.lora(
                fontSize: 16,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (quotes.isEmpty && !isLoadingMore) {
      return SomethingWentWrong(
        title: 'No quotes found.',
        onRetryPressed: () {
          setState(() {
            hasError = false;
            hasMoreData = true;
          });
          _fetchQuotes();
        },
      );
    }

    // Card stack
    return QuoteCardStack(
      quotes: quotes,
      onNeedMoreQuotes: _fetchQuotes,
      onShare: _shareQuote,
      onAuthorTap: _goToAuthor,
    );
  }
}
