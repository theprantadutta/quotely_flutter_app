import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../../components/home_screen/home_screen_list_view/home_screen_quote_list_view.dart';
import '../../components/home_screen/home_screen_quote_filters.dart';
import '../../components/home_screen/home_screen_top_bar.dart';
import '../../components/shared/something_went_wrong.dart';
import '../../constants/colors.dart';
import '../../main.dart';
import '../../riverpods/all_quote_data_provider.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/drift_fact_service.dart';
import '../../services/drift_quote_service.dart';
import '../../state_providers/favorite_fact_ids.dart';
import '../../state_providers/favorite_quote_ids.dart';
import '../legal_content_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAndShowTermsDialog(),
    );
  }

  Future<void> _checkAndShowTermsDialog() async {
    const String termsKey =
        'hasAcceptedTermsV2'; // Use a new key if the logic changes
    final preferences = await SharedPreferences.getInstance();

    final bool hasAccepted = preferences.getBool(termsKey) ?? false;
    if (hasAccepted) {
      return;
    }

    if (!context.mounted) return;

    bool isChecked = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use a StatefulBuilder so the dialog can manage the checkbox state.
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
              title: const Text('Welcome to Quotely!'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Before you begin, please review our policies. By continuing, you agree to our terms.',
                    ),
                    const SizedBox(height: 16),
                    // This RichText widget makes the links tappable
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: 'I have read and agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
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
                              color: Theme.of(context).colorScheme.primary,
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
                    const SizedBox(height: 8),
                    // The single checkbox for acceptance
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              isChecked = value ?? false;
                            });
                          },
                        ),
                        const Expanded(child: Text("I understand and accept.")),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                GestureDetector(
                  onTap: isChecked
                      ? () async {
                          await preferences.setBool(termsKey, true);
                          Navigator.of(dialogContext).pop();
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please accept the terms and conditions.',
                              ),
                            ),
                          );
                        },
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isChecked
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.1, 0.9],
                              colors: [
                                Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.5),
                                kHelperColor.withValues(alpha: 0.5),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade300,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Continue to App',
                      style: TextStyle(
                        color: isChecked
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchQuotes() async {
    if (!hasMoreData || isLoadingMore) return;

    // Analytics: Log pagination event
    if (quotePageNumber > 1) {
      analytics.logEvent(
        name: 'quotes_paginated',
        parameters: {'page_number': quotePageNumber},
      );
    }

    setState(() {
      isLoadingMore = true;
      hasError = false; // Reset error state on new attempt
    });

    try {
      final newQuotes = await ref.read(
        fetchAllQuotesProvider(
          quotePageNumber,
          quotePageSize,
          allSelectedTags,
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
      // Analytics: Log fetch failure
      analytics.logEvent(
        name: 'quote_fetch_failed',
        parameters: {'page_number': quotePageNumber, 'error': e.toString()},
      );
      if (mounted) {
        setState(() {
          hasError = true;
          isLoadingMore = false; // Ensure loading is stopped on error
        });
      }
    }
  }

  Future<void> addAllFavoriteIds() async {
    final allFavoriteQuoteIds =
        await DriftQuoteService.getAllFavoriteQuoteIds();
    talker?.info('All Favorite QuoteIds: $allFavoriteQuoteIds');
    final allFavoriteFactIds = await DriftFactService.getAllFavoriteFactIds();
    talker?.info('All Favorite FactIds: $allFavoriteFactIds');
    ref
        .read(favoriteQuoteIdsProvider.notifier)
        .addOrUpdateIdList(allFavoriteQuoteIds);
    ref
        .read(favoriteFactIdsProvider.notifier)
        .addOrUpdateIdList(allFavoriteFactIds);
  }

  @override
  Widget build(BuildContext context) {
    final isGridView = QuotelyApp.of(context).isGridView;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          children: [
            HomeScreenTopBar(
              loading: isLoadingMore &&
                  quotes.isNotEmpty, // Only show spinner on subsequent loads
              isGridView: isGridView,
              onViewChanged: () =>
                  setState(QuotelyApp.of(context).toggleGridViewEnabled),
            ),
            // BUG FIX & REFINEMENT: The conditional logic below is now more structured
            // to prevent multiple states from showing at once.
            if (!hasError) ...[
              HomeScreenQuoteFilters(
                allSelectedTags: allSelectedTags,
                onSelectedTagChange: (String currentTag) async {
                  // Analytics: Log filter change event
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
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Analytics: Log pull-to-refresh event
                  analytics.logEvent(name: 'quotes_refreshed');
                  setState(() {
                    quotePageNumber = 1;
                    quotes = [];
                    hasMoreData = true;
                  });
                  ref.invalidate(fetchAllQuotesProvider);
                  await _fetchQuotes();
                },
                child: _buildContent(isGridView),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isGridView) {
    // Case 1: Initial load resulted in an error
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

    // Case 2: Initial load is in progress (no data, no error yet)
    if (quotes.isEmpty && isLoadingMore) {
      return isGridView
          ? const HomeScreenQuoteGridViewSkeletor()
          : const HomeScreenQuoteListViewSkeletor();
    }

    // Case 3: No quotes found (e.g., for a specific filter)
    if (quotes.isEmpty && !isLoadingMore) {
      return SomethingWentWrong(
        title: "No quotes found.",
        onRetryPressed: () {
          setState(() {
            hasError = false;
            hasMoreData = true;
          });
          _fetchQuotes();
        },
      );
    }

    // Case 4: Content is available
    return isGridView
        ? HomeScreenQuoteGridView(
            quotes: quotes,
            quotePageNumber: quotePageNumber,
            onLastItemScrolled: _fetchQuotes,
          )
        : HomeScreenQuoteListView(
            quotes: quotes,
            onLastItemScrolled: _fetchQuotes,
          );
  }
}
