import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/authors_screen/author_spotlight_card.dart';
import 'package:quotely_flutter_app/components/authors_screen/single_author_view.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';
import 'package:quotely_flutter_app/riverpods/all_author_data_provider.dart';
import 'package:quotely_flutter_app/util/pagination_seed.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../dtos/author_dto.dart';

class AuthorList extends ConsumerStatefulWidget {
  final TextEditingController authorSearchController;

  const AuthorList({super.key, required this.authorSearchController});

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

  /// The most-quoted author among the loaded results, captured once and frozen
  /// so it doesn't jump around as more pages load. Shown as the spotlight hero
  /// when the user isn't searching.
  AuthorDto? _spotlight;

  bool get _isSearching => widget.authorSearchController.text.trim().isNotEmpty;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    authorScrollController.addListener(_authorScrollListener);
    widget.authorSearchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce both typing AND clearing — clearing the box must restore the
    // full, unfiltered list (it previously got stuck on the last search).
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _refreshAuthors);
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
              PaginationSeed.current,
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
          PaginationSeed.current,
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

  /// Capture the spotlight once from the unfiltered results.
  void _maybeSetSpotlight() {
    if (_spotlight != null || _isSearching || authors.isEmpty) return;
    _spotlight = authors.reduce((a, b) => b.quoteCount > a.quoteCount ? b : a);
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = ref.watch(
      fetchAllAuthorsProvider(
        widget.authorSearchController.text,
        pageNumber,
        pageSize,
        PaginationSeed.current,
      ),
    );

    return Expanded(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.87,
        width: double.infinity,
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
              _maybeSetSpotlight();
              if (authors.isEmpty) return _buildEmpty(context);
              return _buildList(showTrailingSkeleton: hasMoreData);
            },
            error: (error, stackTrace) => Center(
              child: SomethingWentWrong(onRetryPressed: _refreshAuthors),
            ),
            loading: () {
              if (authors.isEmpty || refetching) return _buildInitialSkeleton();
              return _buildList(showTrailingSkeleton: true);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_outlined, size: 80),
            SizedBox(height: 10),
            Text(
              'No Author Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  /// The spotlight header + the de-duped premium author list. The spotlight
  /// author is omitted from the rows (avoids a repeat and a duplicate Hero tag).
  Widget _buildList({required bool showTrailingSkeleton}) {
    final showSpotlight = !_isSearching && _spotlight != null;
    final rows = showSpotlight
        ? authors.where((a) => a.id != _spotlight!.id).toList()
        : authors;

    final headerCount = showSpotlight ? 1 : 0;
    final trailingCount = showTrailingSkeleton ? 1 : 0;

    return ListView.builder(
      controller: authorScrollController,
      itemCount: headerCount + rows.length + trailingCount,
      itemBuilder: (context, index) {
        if (showSpotlight && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthorSpotlightCard(author: _spotlight!),
                const Padding(
                  padding: EdgeInsets.only(top: 18, left: 4, bottom: 2),
                  child: Text(
                    'Browse all',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }
        final i = index - headerCount;
        if (i == rows.length) {
          return Skeletonizer(child: const SingleAuthorViewSkeletor());
        }
        return SingleAuthorView(index: i, author: rows[i]);
      },
    );
  }

  Widget _buildInitialSkeleton() {
    return Skeletonizer(
      child: ListView(
        children: [
          if (!_isSearching) ...[
            const AuthorSpotlightCardSkeleton(),
            const SizedBox(height: 18),
          ],
          for (var i = 0; i < 8; i++) const SingleAuthorViewSkeletor(),
        ],
      ),
    );
  }
}
