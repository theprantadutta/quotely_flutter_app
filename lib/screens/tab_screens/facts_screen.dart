import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/facts_screen/facts_screen_filter_list.dart';
import '../../components/facts_screen/single_fact.dart';
import '../../components/shared/something_went_wrong.dart';
import '../../dtos/ai_fact_dto.dart';
import '../../riverpods/all_facts_data_provider.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/gradients/app_gradients.dart';
import '../../util/pagination_seed.dart';

class FactsScreen extends ConsumerStatefulWidget {
  static const kRouteName = '/facts';

  const FactsScreen({super.key});

  @override
  ConsumerState<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends ConsumerState<FactsScreen> {
  int factPageNumber = 1;
  int factPageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  bool isLoadingMore = false;
  List<AiFactDto> aiFacts = [];
  late ScrollController _scrollController;

  List<String> allSelectedCategory = [];
  List<String> allSelectedProvider = [];

  @override
  void initState() {
    super.initState();
    _fetchFacts();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        hasMoreData &&
        !isLoadingMore) {
      _fetchFacts();
    }
  }

  Future<void> _fetchFacts() async {
    debugPrint('Fetching Ai Facts...');
    if (!hasMoreData || isLoadingMore) return;

    if (!mounted) return;

    setState(() {
      isLoadingMore = true;
      hasError = false;
    });

    try {
      final newFacts = await ref.read(
        fetchAllFactsProvider(
          factPageNumber,
          factPageSize,
          allSelectedCategory,
          allSelectedProvider,
          PaginationSeed.current,
        ).future,
      );
      setState(() {
        hasMoreData = newFacts.aiFacts.length == 10;
        factPageNumber++;
        aiFacts.addAll(newFacts.aiFacts);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.scaffoldBackground(context),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: () {
            factPageNumber = 1;
            aiFacts = [];
            ref.invalidate(fetchAllFactsProvider);
            return _fetchFacts();
          },
          child: Column(
            children: [
              // Header
              _buildHeader(colors),

              // Category filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FactsScreenFilterList(
                  onSelectedCategoryChange: (category) async {
                    setState(() {
                      if (allSelectedCategory.contains(category)) {
                        allSelectedCategory.remove(category);
                      } else {
                        allSelectedCategory.add(category);
                      }
                      factPageNumber = 1;
                      aiFacts = [];
                      hasMoreData = true;
                    });
                    ref.invalidate(fetchAllFactsProvider);
                    await _fetchFacts();
                  },
                  allSelectedCategories: allSelectedCategory,
                ),
              ),

              const SizedBox(height: 8),

              // Content
              Expanded(
                child: _buildContent(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.warmPrimary(context),
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
                Icons.lightbulb_rounded,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facts',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              Text(
                'Expand your knowledge',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Loading indicator
          if (isLoadingMore && aiFacts.isNotEmpty)
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
    if (hasError && aiFacts.isEmpty) {
      return Center(
        child: SomethingWentWrong(
          title: 'Failed to get Facts.',
          onRetryPressed: () {
            setState(() {
              hasError = false;
              hasMoreData = true;
            });
            _fetchFacts();
          },
        ),
      );
    }

    // Loading state
    if (aiFacts.isEmpty && isLoadingMore) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleFactSkeletor(),
          );
        },
      );
    }

    // Empty state
    if (aiFacts.isEmpty && !isLoadingMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 64,
              color: colors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No facts found',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: GoogleFonts.lora(
                fontSize: 14,
                color: colors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Facts list
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: aiFacts.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == aiFacts.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SingleFact(aiFact: aiFacts[index]),
        );
      },
    );
  }
}
