import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/thread/thread.dart';
import '../dtos/author_dto.dart';
import '../dtos/media_title_dto.dart';
import '../navigation/routes.dart';
import '../services/author_service.dart';
import '../services/composer_search_service.dart';
import '../services/scene_repository.dart';
import '../util/pagination_seed.dart';

/// Search across people, titles and lines.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  List<AuthorDto> _people = const [];
  List<MediaTitleDto> _titles = const [];
  List<ThreadMessage> _lines = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _run(value.trim()),
    );
  }

  Future<void> _run(String q) async {
    if (q == _query) return;
    setState(() {
      _query = q;
      _loading = q.isNotEmpty;
    });
    if (q.isEmpty) {
      setState(() {
        _people = const [];
        _titles = const [];
        _lines = const [];
      });
      return;
    }
    final results = await Future.wait([
      AuthorService()
          .getAllAuthors(
            search: q,
            pageNumber: 1,
            pageSize: 6,
            seed: PaginationSeed.current,
          )
          .then((r) => r.authors)
          .catchError((_) => <AuthorDto>[]),
      SceneRepository.instance
          .searchTitles(q)
          .catchError((_) => <MediaTitleDto>[]),
      ComposerSearchService.ask(q, limit: 6),
    ]);
    if (!mounted || q != _query) return;
    setState(() {
      _people = results[0] as List<AuthorDto>;
      _titles = results[1] as List<MediaTitleDto>;
      _lines = results[2] as List<ThreadMessage>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final empty = _people.isEmpty && _titles.isEmpty && _lines.isEmpty;
    return ThreadPage(
      title: 'Search',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.line),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) => _run(v.trim()),
                style: context.qt.chip.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'People, titles, topics…',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: t.mute,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 28),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (_query.isEmpty)
                  const EmptyState(
                    pill: 'Search Quotely',
                    message: 'Try “Mandela”, “One Piece” or “courage”.',
                  )
                else if (_loading)
                  const ThreadSkeleton(count: 2)
                else if (empty)
                  EmptyState(pill: 'Nothing for “$_query”')
                else ...[
                  if (_people.isNotEmpty) ...[
                    const SectionOverline('People'),
                    GroupedList(
                      children: [
                        for (final a in _people)
                          GroupedRow(
                            title: a.name,
                            description: '${a.quoteCount} quotes',
                            chevron: true,
                            onTap: () => context.push(Routes.author(a.slug)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_titles.isNotEmpty) ...[
                    const SectionOverline('Titles'),
                    GroupedList(
                      children: [
                        for (final m in _titles)
                          GroupedRow(
                            title: m.name,
                            description: m.chipMeta,
                            chevron: true,
                            onTap: () => context.push(Routes.title(m.id)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_lines.isNotEmpty) ...[
                    const SectionOverline('Lines'),
                    for (final m in _lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MessageBubble(message: m),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
