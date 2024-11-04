import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/home_screen/home_screen_quote_single_filter.dart';
import '../../dtos/tag_dto.dart';
import '../../riverpods/all_tag_data_provider.dart';

class HomeScreenQuoteFilters extends ConsumerStatefulWidget {
  final List<String> allSelectedTags;
  final Function(String currentTag) onSelectedTagChange;

  const HomeScreenQuoteFilters({
    super.key,
    required this.allSelectedTags,
    required this.onSelectedTagChange,
  });

  @override
  ConsumerState<HomeScreenQuoteFilters> createState() =>
      _HomeScreenQuoteFiltersState();
}

class _HomeScreenQuoteFiltersState
    extends ConsumerState<HomeScreenQuoteFilters> {
  final ScrollController _scrollController = ScrollController();
  int pageNumber = 1;
  final int pageSize = 10;
  List<TagDto> tags = [];
  bool isLoadingMore = false;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchTags(); // Initial fetch
    _scrollController.addListener(_onScroll); // Listen to scroll events
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTags() async {
    if (!hasMoreData || isLoadingMore) return;

    setState(() => isLoadingMore = true);

    try {
      final fetchedTags =
          await ref.read(FetchAllTagsProvider(pageNumber, pageSize).future);

      setState(() {
        isLoadingMore = false;

        // Add only unique tags
        final newTags =
            fetchedTags.tags.where((tag) => !tags.contains(tag)).toList();
        if (newTags.isEmpty) {
          hasMoreData = false; // No new tags; stop further requests
        } else {
          tags.addAll(newTags);
          pageNumber++; // Move to the next page only if new tags were added
        }
      });
    } catch (e) {
      setState(() => isLoadingMore = false); // Handle error
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        hasMoreData &&
        !isLoadingMore) {
      _fetchTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      height: MediaQuery.sizeOf(context).height * 0.038,
      child: tags.isEmpty && isLoadingMore
          ? Skeletonizer(
              child: ListView.builder(
                itemCount: 10,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => HomeScreenQuoteSingleFilter(
                  index: index,
                  title: 'Religion',
                  doesTagExist: false,
                ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: tags.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < tags.length) {
                  final currentTag = tags[index].name;
                  final doesTagExist =
                      widget.allSelectedTags.contains(currentTag);
                  return GestureDetector(
                    onTap: () => widget.onSelectedTagChange(currentTag),
                    child: HomeScreenQuoteSingleFilter(
                      index: index,
                      title: currentTag,
                      doesTagExist: doesTagExist,
                    ),
                  );
                } else {
                  // Display loading indicator at the end while fetching new data
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                      child: LoadingAnimationWidget.hexagonDots(
                        color: kPrimaryColor,
                        size: 20,
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }
}
