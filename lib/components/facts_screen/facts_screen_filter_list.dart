import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../riverpods/all_facts_categories_data_provider.dart';
import '../home_screen/home_screen_quote_single_filter.dart';

// class FactsScreenFilterList extends ConsumerStatefulWidget {
//   final List<String> allSelectedCategories;
//   final Function(String currentCategory) onSelectedCategoryChange;

//   const FactsScreenFilterList({
//     super.key,
//     required this.allSelectedCategories,
//     required this.onSelectedCategoryChange,
//   });

//   @override
//   ConsumerState<FactsScreenFilterList> createState() =>
//       _FactsScreenFilterListState();
// }

// class _FactsScreenFilterListState extends ConsumerState<FactsScreenFilterList> {
//   final ScrollController _scrollController = ScrollController();
//   int pageNumber = 1;
//   final int pageSize = 10;
//   List<String> aiCategories = [];
//   bool isLoadingMore = false;
//   bool hasMoreData = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchAiCategories(); // Initial fetch
//     _scrollController.addListener(_onScroll); // Listen to scroll events
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchAiCategories() async {
//     if (!hasMoreData || isLoadingMore) return;

//     setState(() => isLoadingMore = true);

//     try {
//       final fetchedCategories = await ref
//           .read(FetchAllFactsCategoriesProvider(pageNumber, pageSize).future);

//       setState(() {
//         isLoadingMore = false;

//         // Add only unique tags
//         final newCategories = fetchedCategories
//             .where((tag) => !aiCategories.contains(tag))
//             .toList();
//         if (newCategories.isEmpty) {
//           hasMoreData = false; // No new tags; stop further requests
//         } else {
//           aiCategories.addAll(newCategories);
//           pageNumber++; // Move to the next page only if new tags were added
//         }
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => isLoadingMore = false); // Handle error
//     }
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//             _scrollController.position.maxScrollExtent - 200 &&
//         hasMoreData &&
//         !isLoadingMore) {
//       _fetchAiCategories();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final kPrimaryColor = Theme.of(context).primaryColor;
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 5),
//       height: MediaQuery.sizeOf(context).height * 0.038,
//       child: aiCategories.isEmpty && isLoadingMore
//           ? Skeletonizer(
//               child: ListView.builder(
//                 itemCount: 10,
//                 scrollDirection: Axis.horizontal,
//                 itemBuilder: (context, index) => AllFilterList(
//                   index: index,
//                   title: 'Religion',
//                   isSelected: false,
//                 ),
//               ),
//             )
//           : ListView.builder(
//               controller: _scrollController,
//               scrollDirection: Axis.horizontal,
//               itemCount: aiCategories.length + (isLoadingMore ? 1 : 0),
//               itemBuilder: (context, index) {
//                 if (index < aiCategories.length) {
//                   final currentCategory = aiCategories[index];
//                   final isSelected =
//                       widget.allSelectedCategories.contains(currentCategory);
//                   return GestureDetector(
//                     onTap: () =>
//                         widget.onSelectedCategoryChange(currentCategory),
//                     child: AllFilterList(
//                       index: index,
//                       title: currentCategory,
//                       isSelected: isSelected,
//                     ),
//                   );
//                 } else {
//                   // Display loading indicator at the end while fetching new data
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                     child: Center(
//                       child: LoadingAnimationWidget.hexagonDots(
//                         color: kPrimaryColor,
//                         size: 20,
//                       ),
//                     ),
//                   );
//                 }
//               },
//             ),
//     );
//   }
// }

class FactsScreenFilterList extends ConsumerStatefulWidget {
  final List<String> allSelectedCategories;
  final Function(String currentCategory) onSelectedCategoryChange;

  const FactsScreenFilterList({
    super.key,
    required this.allSelectedCategories,
    required this.onSelectedCategoryChange,
  });

  @override
  ConsumerState<FactsScreenFilterList> createState() =>
      _FactsScreenFilterListState();
}

class _FactsScreenFilterListState extends ConsumerState<FactsScreenFilterList> {
  final ScrollController _scrollController = ScrollController();
  int pageNumber = 1;
  final int pageSize = 10;
  List<String> aiCategories = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  bool hasError = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAiCategories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAiCategories() async {
    if (!hasMoreData || isLoadingMore) return;

    // Set loading states
    if (pageNumber == 1) {
      setState(() => isLoading = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    try {
      final fetchedCategories = await ref
          .read(FetchAllFactsCategoriesProvider(pageNumber, pageSize).future);

      setState(() {
        hasError = false;
        errorMessage = null;

        // Add only unique tags
        final newCategories = fetchedCategories
            .where((tag) => tag.isNotEmpty && !aiCategories.contains(tag))
            .toList();

        if (newCategories.isEmpty) {
          hasMoreData = false;
        } else {
          aiCategories.addAll(newCategories);
          pageNumber++;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasError = true;
        errorMessage = e is FormatException
            ? 'Invalid data format'
            : 'Failed to load categories';
      });
      if (pageNumber == 1) {
        aiCategories.clear();
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        hasMoreData &&
        !isLoadingMore) {
      _fetchAiCategories();
    }
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Center(
        child: LoadingAnimationWidget.hexagonDots(
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          errorMessage ?? 'Error loading categories',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('No categories available'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && pageNumber == 1) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        height: MediaQuery.sizeOf(context).height * 0.038,
        child: Skeletonizer(
          child: ListView.builder(
            itemCount: 10,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => AllFilterList(
              index: index,
              title: 'Religion',
              isSelected: false,
            ),
          ),
        ),
      );
    }

    if (hasError && aiCategories.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        height: MediaQuery.sizeOf(context).height * 0.038,
        child: _buildErrorWidget(),
      );
    }

    if (aiCategories.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        height: MediaQuery.sizeOf(context).height * 0.038,
        child: _buildEmptyState(),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      height: MediaQuery.sizeOf(context).height * 0.038,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: aiCategories.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < aiCategories.length) {
            final currentCategory = aiCategories[index];
            final isSelected =
                widget.allSelectedCategories.contains(currentCategory);
            return GestureDetector(
              onTap: () => widget.onSelectedCategoryChange(currentCategory),
              child: AllFilterList(
                index: index,
                title: currentCategory,
                isSelected: isSelected,
              ),
            );
          } else {
            return _buildLoadingIndicator();
          }
        },
      ),
    );
  }
}
