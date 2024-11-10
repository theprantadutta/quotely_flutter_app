import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/authors_screen/single_author_view.dart';
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
  List<AuthorDto> quotes = [];
  bool refetching = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    authorScrollController.addListener(_authorScrollListener);
    widget.authorSearchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      _refreshQuotes,
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

  Future<void> _refreshQuotes() async {
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
        quotes = [];
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
          onRefresh: _refreshQuotes,
          child: quoteProvider.when(
            skipLoadingOnRefresh: false,
            data: (data) {
              final authorsFromDb = data.authors;
              if (authorsFromDb.length < pageSize) {
                hasMoreData = false;
              }
              for (var author in authorsFromDb) {
                // if (!quotes.any((n) => n.quoteId == quote.quoteId)) {
                quotes.add(author);
                // }
              }
              return ListView.builder(
                controller: authorScrollController,
                itemCount: quotes.length + (hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == quotes.length) {
                    return const SingleAuthorViewSkeletor();
                  }
                  return SingleAuthorView(
                    index: index,
                    author: quotes[index],
                  );
                },
              );
            },
            error: (error, stackTrace) => const Center(
              child: Text('Something Went Wrong'),
            ),
            loading: () {
              if (quotes.isEmpty || refetching) {
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
                itemCount: quotes.length + 1,
                itemBuilder: (context, index) {
                  if (index == quotes.length) {
                    return const SingleAuthorViewSkeletor();
                  }
                  return SingleAuthorView(
                    index: index,
                    author: quotes[index],
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
