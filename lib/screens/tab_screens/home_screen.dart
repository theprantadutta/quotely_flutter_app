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
import '../../services/app_info_service.dart';
import '../../services/app_service.dart';
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

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _fetchQuotes();
    Future.microtask(() => checkForMaintenanceAndAppUpdate());
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
      // showErrorToast(
      //   context: context,
      //   title: 'Something Went Wrong',
      //   description: 'Failed to check App Update,',
      // );
    }
  }

  Future<void> _fetchQuotes() async {
    debugPrint('Fetching Quotes...');
    if (!hasMoreData || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
      hasError = false;
    });

    try {
      final newQuotes = await ref.read(fetchAllQuotesProvider(
        quotePageNumber,
        quotePageSize,
        allSelectedTags,
      ).future);
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
    final isGridView = MyApp.of(context).isGridView;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
        child: RefreshIndicator(
          onRefresh: () {
            quotePageNumber = 1;
            quotes = [];
            ref.invalidate(fetchAllQuotesProvider);
            return _fetchQuotes();
          },
          child: Column(
            children: [
              HomeScreenTopBar(
                loading: isLoadingMore,
                isGridView: isGridView,
                onViewChanged: () =>
                    setState(MyApp.of(context).toggleGridViewEnabled),
              ),
              // Display error message if there's an error
              if (hasError)
                Expanded(
                  child: Center(
                    child: SomethingWentWrong(
                      title: 'Failed to get Quotes.',
                      onRetryPressed: _fetchQuotes,
                    ),
                  ),
                ),
              HomeScreenQuoteFilters(
                allSelectedTags: allSelectedTags,
                onSelectedTagChange: (String currentTag) async {
                  setState(() {
                    if (allSelectedTags.contains(currentTag)) {
                      // Remove the tag if it already exists
                      allSelectedTags.remove(currentTag);
                    } else {
                      // Add the tag if it does not exist
                      allSelectedTags.add(currentTag);
                    }
                    quotePageNumber = 1;
                    quotes = [];
                  });

                  ref.invalidate(fetchAllQuotesProvider);
                  await _fetchQuotes();
                },
              ),
              // Display skeleton loaders when there’s no error and no data
              if (!hasError && quotes.isEmpty)
                Expanded(
                  child: isGridView
                      ? const HomeScreenQuoteGridViewSkeletor()
                      : const HomeScreenQuoteListViewSkeletor(),
                ),

              // Display the main content if there are quotes available
              if (!hasError && quotes.isNotEmpty)
                Expanded(
                  child: isGridView
                      ? HomeScreenQuoteGridView(
                          quotes: quotes,
                          quotePageNumber: quotePageNumber,
                          onLastItemScrolled: _fetchQuotes,
                        )
                      : HomeScreenQuoteListView(
                          quotes: quotes,
                          onLastItemScrolled: _fetchQuotes,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
