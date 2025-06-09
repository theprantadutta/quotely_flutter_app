// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:quotely_flutter_app/dtos/quote_dto.dart';

// import '../../components/home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
// import '../../components/home_screen/home_screen_list_view/home_screen_quote_list_view.dart';
// import '../../components/home_screen/home_screen_quote_filters.dart';
// import '../../components/home_screen/home_screen_top_bar.dart';
// import '../../components/shared/something_went_wrong.dart';
// import '../../main.dart';
// import '../../riverpods/all_quote_data_provider.dart';
// import '../../services/app_info_service.dart';
// import '../../services/app_service.dart';
// import '../../services/drift_fact_service.dart';
// import '../../services/drift_quote_service.dart';
// import '../../state_providers/favorite_fact_ids.dart';
// import '../../state_providers/favorite_quote_ids.dart';
// import '../../util/functions.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   static const kRouteName = '/home';
//   const HomeScreen({super.key});

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   int quotePageNumber = 1;
//   int quotePageSize = 10;
//   bool hasMoreData = true;
//   bool hasError = false;
//   bool isLoadingMore = false;
//   List<QuoteDto> quotes = [];

//   List<String> allSelectedTags = [];

//   @override
//   void initState() {
//     super.initState();
//     FlutterNativeSplash.remove();
//     _fetchQuotes();
//     Future.microtask(() => checkForMaintenanceAndAppUpdate());
//     addAllFavoriteIds();
//   }

//   Future<void> checkForMaintenanceAndAppUpdate() async {
//     debugPrint('Running checkForMaintenanceAndAppUpdate...');
//     try {
//       final appUpdateInfo = await AppInfoService().getAppUpdateInfo();
//       // Check Maintenance
//       final maintenanceBreak = appUpdateInfo.maintenanceBreak;
//       debugPrint('Maintenance Break: $maintenanceBreak');
//       if (maintenanceBreak) {
//         debugPrint('Maintenance Break, returning...');
//         if (!mounted) return;
//         await AppService.showMaintenanceDialog(context);
//         return;
//       }
//       PackageInfo packageInfo = await PackageInfo.fromPlatform();
//       String currentAppVersion = packageInfo.version;
//       final currentVersion = appUpdateInfo.currentVersion;
//       debugPrint('Current App Version: $currentAppVersion');
//       if (!mounted) return;
//       if (compareVersion(currentVersion, currentAppVersion) == 1) {
//         AppService.showUpdateDialog(context, currentVersion);
//       }
//     } catch (e) {
//       debugPrint('Something went wrong while checking for app update');
//       debugPrint(e.toString());
//       // showErrorToast(
//       //   context: context,
//       //   title: 'Something Went Wrong',
//       //   description: 'Failed to check App Update,',
//       // );
//     }
//   }

//   Future<void> _fetchQuotes() async {
//     debugPrint('Fetching Quotes...');
//     if (!hasMoreData || isLoadingMore) return;

//     setState(() {
//       isLoadingMore = true;
//       hasError = false;
//     });

//     try {
//       final newQuotes = await ref.read(fetchAllQuotesProvider(
//         quotePageNumber,
//         quotePageSize,
//         allSelectedTags,
//       ).future);
//       setState(() {
//         hasMoreData = newQuotes.quotes.length == 10;
//         quotePageNumber++;
//         quotes.addAll(newQuotes.quotes);
//         isLoadingMore = false;
//       });
//     } catch (e) {
//       if (kDebugMode) print(e);
//       if (mounted) {
//         setState(() {
//           hasError = true;
//           isLoadingMore = false;
//         });
//       }
//     }
//   }

//   Future<void> addAllFavoriteIds() async {
//     final allFavoriteQuoteIds =
//         await DriftQuoteService.getAllFavoriteQuoteIds();
//     talker?.info('All Favorite QuoteIds: $allFavoriteQuoteIds');
//     final allFavoriteFactIds = await DriftFactService.getAllFavoriteFactIds();
//     talker?.info('All Favorite FactIds: $allFavoriteFactIds');
//     ref
//         .read(favoriteQuoteIdsProvider.notifier)
//         .addOrUpdateIdList(allFavoriteQuoteIds);
//     ref
//         .read(favoriteFactIdsProvider.notifier)
//         .addOrUpdateIdList(allFavoriteFactIds);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isGridView = QuotelyApp.of(context).isGridView;
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(
//           vertical: 8,
//           horizontal: 10,
//         ),
//         child: RefreshIndicator(
//           onRefresh: () {
//             quotePageNumber = 1;
//             quotes = [];
//             ref.invalidate(fetchAllQuotesProvider);
//             return _fetchQuotes();
//           },
//           child: Column(
//             children: [
//               HomeScreenTopBar(
//                 loading: isLoadingMore,
//                 isGridView: isGridView,
//                 onViewChanged: () =>
//                     setState(QuotelyApp.of(context).toggleGridViewEnabled),
//               ),
//               // Display error message if there's an error
//               if (hasError)
//                 Expanded(
//                   child: Center(
//                     child: SomethingWentWrong(
//                       title: 'Failed to get Quotes.',
//                       onRetryPressed: _fetchQuotes,
//                     ),
//                   ),
//                 ),
//               HomeScreenQuoteFilters(
//                 allSelectedTags: allSelectedTags,
//                 onSelectedTagChange: (String currentTag) async {
//                   setState(() {
//                     if (allSelectedTags.contains(currentTag)) {
//                       // Remove the tag if it already exists
//                       allSelectedTags.remove(currentTag);
//                     } else {
//                       // Add the tag if it does not exist
//                       allSelectedTags.add(currentTag);
//                     }
//                     quotePageNumber = 1;
//                     quotes = [];
//                   });

//                   ref.invalidate(fetchAllQuotesProvider);
//                   await _fetchQuotes();
//                 },
//               ),
//               // Display skeleton loaders when there’s no error and no data
//               if (!hasError && quotes.isEmpty)
//                 Expanded(
//                   child: isGridView
//                       ? const HomeScreenQuoteGridViewSkeletor()
//                       : const HomeScreenQuoteListViewSkeletor(),
//                 ),

//               // Display the main content if there are quotes available
//               if (!hasError && quotes.isNotEmpty)
//                 Expanded(
//                   child: isGridView
//                       ? HomeScreenQuoteGridView(
//                           quotes: quotes,
//                           quotePageNumber: quotePageNumber,
//                           onLastItemScrolled: _fetchQuotes,
//                         )
//                       : HomeScreenQuoteListView(
//                           quotes: quotes,
//                           onLastItemScrolled: _fetchQuotes,
//                         ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';

import '../../components/home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../../components/home_screen/home_screen_list_view/home_screen_quote_list_view.dart';
import '../../components/home_screen/home_screen_quote_filters.dart';
import '../../components/home_screen/home_screen_top_bar.dart';
import '../../components/shared/something_went_wrong.dart';
import '../../main.dart';
import '../../riverpods/all_quote_data_provider.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/app_info_service.dart';
import '../../services/app_service.dart';
import '../../services/drift_fact_service.dart';
import '../../services/drift_quote_service.dart';
import '../../state_providers/favorite_fact_ids.dart';
import '../../state_providers/favorite_quote_ids.dart';
import '../../util/functions.dart';

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
    Future.microtask(() => checkForMaintenanceAndAppUpdate());
    addAllFavoriteIds();
  }

  Future<void> checkForMaintenanceAndAppUpdate() async {
    debugPrint('Running checkForMaintenanceAndAppUpdate...');
    try {
      final appUpdateInfo = await AppInfoService().getAppUpdateInfo();
      // Check Maintenance
      final maintenanceBreak = appUpdateInfo.maintenanceBreak;
      debugPrint('Maintenance Break: $maintenanceBreak');
      if (maintenanceBreak) {
        debugPrint('Maintenance Break, returning...');
        if (!mounted) return;
        await AppService.showMaintenanceDialog(context);
        return;
      }
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentAppVersion = packageInfo.version;
      final currentVersion = appUpdateInfo.currentVersion;
      debugPrint('Current App Version: $currentAppVersion');
      if (!mounted) return;
      if (compareVersion(currentVersion, currentAppVersion) == 1) {
        AppService.showUpdateDialog(context, currentVersion);
      }
    } catch (e) {
      debugPrint('Something went wrong while checking for app update');
      debugPrint(e.toString());
    }
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
      final newQuotes = await ref.read(fetchAllQuotesProvider(
        quotePageNumber,
        quotePageSize,
        allSelectedTags,
      ).future);
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
        parameters: {
          'page_number': quotePageNumber,
          'error': e.toString(),
        },
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
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
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
                  analytics.logEvent(name: 'quote_filter_changed', parameters: {
                    'toggled_tag': currentTag,
                    'all_selected_tags': allSelectedTags.join(','),
                  });
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
        onRetryPressed: () => _fetchQuotes(),
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
