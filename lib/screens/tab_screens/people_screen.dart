import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../components/thread/thread.dart';
import '../../dtos/author_dto.dart';
import '../../dtos/character_dto.dart';
import '../../navigation/routes.dart';
import '../../riverpods/all_author_data_provider.dart';
import '../../riverpods/scene_providers.dart';
import '../../state_providers/recent_people.dart';
import '../../state_providers/scene_state.dart';
import '../../util/pagination_seed.dart';

enum _PeopleTab { authors, characters }

/// People: authors and characters, chat-list style.
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  _PeopleTab _tab = _PeopleTab.authors;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  String _query = '';

  final List<AuthorDto> _authors = [];
  int _authorPage = 1;
  bool _authorsHasMore = true;
  bool _authorsLoading = false;
  bool _authorsError = false;
  int? _authorTotal;

  final List<CharacterDto> _characters = [];
  int _characterPage = 1;
  bool _charactersHasMore = true;
  bool _charactersLoading = false;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 500) _fetch();
    });
    _search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        final q = _search.text.trim();
        if (q == _query) return;
        setState(() {
          _query = q;
          _resetLists();
        });
        _fetch();
      });
    });
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _resetLists() {
    _authors.clear();
    _authorPage = 1;
    _authorsHasMore = true;
    _authorsError = false;
    _characters.clear();
    _characterPage = 1;
    _charactersHasMore = true;
  }

  Future<void> _fetch() =>
      _tab == _PeopleTab.authors ? _fetchAuthors() : _fetchCharacters();

  Future<void> _fetchAuthors() async {
    if (_authorsLoading || !_authorsHasMore) return;
    setState(() {
      _authorsLoading = true;
      _authorsError = false;
    });
    final query = _query;
    try {
      final res = await ref.read(
        fetchAllAuthorsProvider(
          query,
          _authorPage,
          _pageSize,
          PaginationSeed.current,
        ).future,
      );
      if (!mounted || query != _query) return;
      setState(() {
        if (query.isEmpty && res.pagination.totalItemCount > 0) {
          _authorTotal = res.pagination.totalItemCount;
        }
        _authorsHasMore = res.authors.length == _pageSize;
        _authorPage++;
        _authors.addAll(
          res.authors.where((a) => !_authors.any((x) => x.id == a.id)),
        );
      });
    } catch (_) {
      if (mounted) setState(() => _authorsError = true);
    } finally {
      if (mounted) setState(() => _authorsLoading = false);
    }
  }

  Future<void> _fetchCharacters() async {
    if (_charactersLoading || !_charactersHasMore) return;
    setState(() => _charactersLoading = true);
    final query = _query;
    try {
      final page = await ref.read(
        charactersPageProvider(query, _characterPage).future,
      );
      if (!mounted || query != _query) return;
      setState(() {
        _charactersHasMore = page.length == 20;
        _characterPage++;
        _characters.addAll(
          page.where((c) => !_characters.any((x) => x.id == c.id)),
        );
      });
    } catch (_) {
      _charactersHasMore = false;
    } finally {
      if (mounted) setState(() => _charactersLoading = false);
    }
  }

  void _openAuthor(AuthorDto a) {
    ref
        .read(recentPeopleProvider.notifier)
        .add(
          RecentPerson(
            kind: PersonKind.author,
            id: a.slug,
            name: a.name,
            imageUrl: a.imageUrl,
          ),
        );
    context.push(Routes.author(a.slug));
  }

  void _openCharacter(CharacterDto c) {
    ref
        .read(recentPeopleProvider.notifier)
        .add(
          RecentPerson(
            kind: PersonKind.character,
            id: c.id,
            name: c.name,
            imageUrl: c.avatarUrl,
            titleId: c.titleId,
          ),
        );
    context.push('${Routes.titleBase}/${c.titleId}?character=${c.id}');
  }

  String _count(int n) => NumberFormat.decimalPattern().format(n);

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final characterCount = ref.watch(localCharacterCountProvider).value;
    final recents = ref.watch(recentPeopleProvider);
    final followed = ref.watch(followedAuthorsProvider);
    final stories = [
      for (final p in recents)
        if ((p.kind == PersonKind.author) == (_tab == _PeopleTab.authors)) p,
    ];
    final isAuthors = _tab == _PeopleTab.authors;

    return SafeArea(
      bottom: false,
      child: ThreadColumn(
        child: RefreshIndicator.adaptive(
          onRefresh: () async {
            ref.invalidate(fetchAllAuthorsProvider);
            ref.invalidate(charactersPageProvider);
            setState(_resetLists);
            await _fetch();
          },
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: ScreenHeader(
                  title: 'People',
                  subtitle: 'Authors and characters you can follow',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: SegmentedPill<_PeopleTab>(
                    options: [
                      ChipOption(
                        _PeopleTab.authors,
                        _authorTotal == null
                            ? 'Authors'
                            : 'Authors ${_count(_authorTotal!)}',
                      ),
                      ChipOption(
                        _PeopleTab.characters,
                        characterCount == null || characterCount == 0
                            ? 'Characters'
                            : 'Characters ${_count(characterCount)}',
                      ),
                    ],
                    value: _tab,
                    onChanged: (tab) {
                      setState(() => _tab = tab);
                      _fetch();
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: t.line),
                    ),
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      style: context.qt.chip.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: isAuthors
                            ? 'Search people'
                            : 'Search characters',
                        hintStyle: context.qt.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.mute,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: t.mute,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 28,
                        ),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: t.mute,
                                ),
                                onPressed: _search.clear,
                              ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (stories.isNotEmpty && _query.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      itemCount: stories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final p = stories[i];
                        return StoryAvatar(
                          name: p.name.split(' ').last,
                          imageUrl: p.imageUrl,
                          // Ring = someone you follow; seen = just visited.
                          isNew:
                              p.kind == PersonKind.author &&
                              followed.contains(p.id),
                          onTap: () => p.kind == PersonKind.author
                              ? context.push(Routes.author(p.id))
                              : context.push(
                                  '${Routes.titleBase}/${p.titleId}?character=${p.id}',
                                ),
                        );
                      },
                    ),
                  ),
                ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 18, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: SectionOverline('All', padding: EdgeInsets.zero),
                ),
              ),
              if (isAuthors) ..._authorSlivers() else ..._characterSlivers(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _authorSlivers() => [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: _authors.length,
        itemBuilder: (context, i) {
          final a = _authors[i];
          return _PersonRow(
            name: a.name,
            imageUrl: a.imageUrl,
            heroTag: a.slug,
            count: a.quoteCount,
            preview: a.description.isNotEmpty ? a.description : a.bio,
            onTap: () => _openAuthor(a),
          );
        },
      ),
    ),
    SliverToBoxAdapter(
      child: _authorsError && _authors.isEmpty
          ? ErrorBubble(onRetry: _fetchAuthors)
          : _authorsLoading
          ? (_authors.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: PeopleListSkeleton(),
                  )
                : const LoadMoreIndicator(person: true))
          : _authors.isEmpty
          ? EmptyState(
              pill: _query.isEmpty
                  ? 'No authors yet'
                  : 'No one called “$_query”',
            )
          : const SizedBox(height: 24),
    ),
  ];

  List<Widget> _characterSlivers() => [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: _characters.length,
        itemBuilder: (context, i) {
          final c = _characters[i];
          return _PersonRow(
            name: c.name,
            imageUrl: c.avatarUrl,
            count: c.quoteCount,
            preview: c.titleName,
            onTap: () => _openCharacter(c),
          );
        },
      ),
    ),
    SliverToBoxAdapter(
      child: _charactersLoading
          ? (_characters.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: PeopleListSkeleton(),
                  )
                : const LoadMoreIndicator(person: true))
          : _characters.isEmpty
          ? EmptyState(
              pill: _query.isEmpty
                  ? 'No characters yet'
                  : 'No one called “$_query”',
            )
          : const SizedBox(height: 24),
    ),
  ];
}

/// Chat-list row: 46 avatar, name, "N quotes" on the right, one-line preview.
class _PersonRow extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final Object? heroTag;
  final int count;
  final String preview;
  final VoidCallback onTap;

  const _PersonRow({
    required this.name,
    required this.imageUrl,
    this.heroTag,
    required this.count,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name, $count quotes',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              QAvatar(
                name: name,
                imageUrl: imageUrl,
                size: 46,
                heroTag: heroTag,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.qt.rowTitle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          count == 1 ? '1 quote' : '$count quotes',
                          style: context.qt.caption,
                        ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.qt.meta.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
