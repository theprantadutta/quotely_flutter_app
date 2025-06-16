import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/authors_screen/single_author_view.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';
import 'package:quotely_flutter_app/riverpods/all_author_data_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../dtos/author_dto.dart';

class AuthorList extends ConsumerStatefulWidget {
  final TextEditingController authorSearchController;

  const AuthorList({
    super.key,
    required this.authorSearchController,
  });

  @override
  ConsumerState<AuthorList> createState() => _AuthorListState();
}

class _AuthorListState extends ConsumerState<AuthorList> {
  ScrollController authorScrollController = ScrollController();
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool hasError = false;
  List<AuthorDto> authors = [];
  bool refetching = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    authorScrollController.addListener(_authorScrollListener);
    widget.authorSearchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (widget.authorSearchController.text.isEmpty) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      _refreshAuthors,
    );
  }

  Future<void> _authorScrollListener() async {
    if (authorScrollController.position.pixels ==
        authorScrollController.position.maxScrollExtent) {
      try {
        if (hasMoreData) {
          setState(() {
            hasError = false;
            pageNumber++;
          });
          final _ = await ref.refresh(
            fetchAllAuthorsProvider(
              widget.authorSearchController.text,
              pageNumber,
              pageSize,
            ).future,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        setState(() => hasError = true);
      }
    }
  }

  @override
  void dispose() {
    authorScrollController.dispose();
    widget.authorSearchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _refreshAuthors() async {
    debugPrint('Refreshing Quotes...');
    try {
      setState(() {
        refetching = true;
      });
      final _ = await ref.refresh(
        fetchAllAuthorsProvider(
          widget.authorSearchController.text,
          pageNumber,
          pageSize,
        ).future,
      );
      setState(() {
        authors = [];
        pageNumber = 1;
        hasError = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        refetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = ref.watch(
      fetchAllAuthorsProvider(
        widget.authorSearchController.text,
        pageNumber,
        pageSize,
      ),
    );

    return Expanded(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.87,
        width: MediaQuery.sizeOf(context).width,
        // margin: EdgeInsets.symmetric(vertical: 5),
        child: RefreshIndicator.adaptive(
          onRefresh: _refreshAuthors,
          child: quoteProvider.when(
            skipLoadingOnRefresh: false,
            data: (data) {
              final authorsFromDb = data.authors;
              if (authorsFromDb.length < pageSize) {
                hasMoreData = false;
              }
              for (var author in authorsFromDb) {
                if (!authors.any((n) => n.id == author.id)) {
                  authors.add(author);
                }
              }
              if (authors.isEmpty) {
                return SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty_outlined,
                          size: 80,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No Author Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: authorScrollController,
                itemCount: authors.length + (hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == authors.length) {
                    return Skeletonizer(
                      child: const SingleAuthorViewSkeletor(),
                    );
                  }
                  return SingleAuthorView(
                    index: index,
                    author: authors[index],
                  );
                },
              );
            },
            error: (error, stackTrace) => Center(
              child: SomethingWentWrong(
                onRetryPressed: _refreshAuthors,
              ),
            ),
            loading: () {
              if (authors.isEmpty || refetching) {
                return Skeletonizer(
                  child: ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) =>
                        const SingleAuthorViewSkeletor(),
                  ),
                );
              }
              return ListView.builder(
                controller: authorScrollController,
                itemCount: authors.length + 1,
                itemBuilder: (context, index) {
                  if (index == authors.length) {
                    return Skeletonizer(
                      child: const SingleAuthorViewSkeletor(),
                    );
                  }
                  return SingleAuthorView(
                    index: index,
                    author: authors[index],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
