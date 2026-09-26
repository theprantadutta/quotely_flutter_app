import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/thread/thread.dart';
import '../../dtos/media_title_dto.dart';
import '../../dtos/scene_quote_dto.dart';
import '../../navigation/bottom-navigation/bottom_navigation_layout.dart';
import '../../navigation/routes.dart';
import '../../riverpods/scene_providers.dart';
import '../../service_locator/init_service_locators.dart';
import '../../state_providers/scene_state.dart';

enum _Mode { watch, browse }

/// Scenes: lines from movies, shows, anime and games. "Watch" is the
/// full-screen feed over the title's poster; "Browse" lists titles.
class ScenesScreen extends ConsumerStatefulWidget {
  const ScenesScreen({super.key});

  @override
  ConsumerState<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends ConsumerState<ScenesScreen> {
  final _scroll = ScrollController();
  final _pager = PageController();
  _Mode _mode = _Mode.watch;
  int _index = 0;

  /// null = All.
  MediaType? _type;
  bool _typeInitialized = false;

  final List<SceneQuoteDto> _lines = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 600) _fetch();
    });
    _initType();
  }

  /// A single SCREEN interest preselects its chip; several (or none) → All.
  Future<void> _initType() async {
    await ref.read(screenInterestsProvider.notifier).ready;
    final picks = ref.read(screenInterestsProvider);
    if (!mounted) return;
    setState(() {
      _type = picks.length == 1 ? picks.first : null;
      _typeInitialized = true;
    });
    _fetch();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pager.dispose();
    super.dispose();
  }

  String get _typesCsv => _type == null ? '' : _type!.name;

  Future<void> _fetch() async {
    if (_loading || !_hasMore || !_typeInitialized) return;
    setState(() => _loading = true);
    try {
      final page = await ref.read(
        sceneQuotesPageProvider(
          pageNumber: _page,
          pageSize: 12,
          typesCsv: _typesCsv,
          sort: 'popular',
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _hasMore = page.length == 12;
        _page++;
        _lines.addAll(page.where((l) => !_lines.any((x) => x.id == l.id)));
      });
    } catch (_) {
      _hasMore = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setType(MediaType? type) {
    setState(() {
      _type = type;
      _lines.clear();
      _page = 1;
      _hasMore = true;
      _index = 0;
    });
    if (_pager.hasClients) _pager.jumpToPage(0);
    getIt.get<FirebaseAnalytics>().logEvent(
      name: 'scenes_type_changed',
      parameters: {'type': type?.name ?? 'all'},
    );
    _fetch();
  }

  Future<void> _refresh() async {
    ref.invalidate(sceneOfTheDayProvider);
    ref.invalidate(trendingTitlesProvider);
    ref.invalidate(sceneQuotesPageProvider);
    setState(() {
      _lines.clear();
      _page = 1;
      _hasMore = true;
    });
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final shield = ref.watch(spoilerShieldProvider);
    final t = context.q;
    final sotd = ref.watch(sceneOfTheDayProvider).value?.sceneQuote;
    final feed = [
      ?sotd,
      for (final l in _lines)
        if (l.id != sotd?.id) l,
    ];
    final index = _index.clamp(0, feed.isEmpty ? 0 : feed.length - 1);
    final current = feed.isEmpty ? null : feed[index];

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 10, 0),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              'Scenes',
              style: context.qt.titlePush.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          MiniSegmented<_Mode>(
            options: const [
              ChipOption(_Mode.watch, 'Watch'),
              ChipOption(_Mode.browse, 'Browse'),
            ],
            value: _mode,
            onChanged: (m) {
              setState(() => _mode = m);
              // Scenes is tab 1; only Watch runs behind the nav.
              immersiveTabs.value = {
                ...immersiveTabs.value.where((i) => i != 1),
                if (m == _Mode.watch) 1,
              };
            },
          ),
          const Spacer(),
          CircleIconButton(
            icon: shield ? Icons.shield_rounded : Icons.shield_outlined,
            semanticLabel: shield ? 'Spoiler shield on' : 'Spoiler shield off',
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(spoilerShieldProvider.notifier).toggle();
            },
          ),
          CircleIconButton(
            icon: Icons.search_rounded,
            semanticLabel: 'Search titles',
            onTap: () => context.push(Routes.search),
          ),
        ],
      ),
    );

    final types = FilterChips<MediaType?>(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      options: [
        const ChipOption(null, 'All'),
        for (final t in MediaType.values) ChipOption(t, t.plural),
      ],
      isSelected: (t) => t == _type,
      onSelected: _setType,
    );

    if (_mode == _Mode.watch) {
      final navInset = MediaQuery.paddingOf(context).bottom;
      return Stack(
        fit: StackFit.expand,
        children: [
          SpotlightBackdrop(
            tint: t.tintFor(DateTime.now().add(const Duration(days: 2))),
            imageUrl: current?.posterUrl,
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                header,
                types,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: navInset),
                    child: _watch(feed, sotd),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 6,
            bottom: 18 + navInset,
            child: SpotlightRail(
              message: current == null
                  ? null
                  : ThreadMessage.fromScene(current),
            ),
          ),
        ],
      );
    }

    final followed = ref.watch(followedTitlesProvider);
    final trending = ref.watch(trendingTitlesProvider(_typesCsv));
    return SafeArea(
      bottom: false,
      child: ThreadColumn(
        child: Column(
          children: [
            header,
            types,
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: _SectionTitle('Trending titles'),
                    ),
                    SliverToBoxAdapter(
                      child: _PosterRow(
                        titles: trending.value,
                        loading: trending.isLoading,
                      ),
                    ),
                    if (followed.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: _SectionTitle('From titles you follow'),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.list(
                          children: [
                            for (final id in followed.keys.take(4))
                              _FollowedTitleLines(titleId: id),
                          ],
                        ),
                      ),
                    ],
                    if (_type == null)
                      for (final t in MediaType.values) ...[
                        SliverToBoxAdapter(child: _SectionTitle(t.plural)),
                        SliverToBoxAdapter(child: _TypeRow(type: t)),
                      ],
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _watch(List<SceneQuoteDto> feed, SceneQuoteDto? sotd) {
    if (feed.isEmpty) {
      if (_loading || !_typeInitialized) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }
      return EmptyState(
        pill: 'No lines here yet',
        message: _type == null
            ? 'New scenes arrive every week.'
            : 'No ${_type!.plural.toLowerCase()} yet. New scenes arrive every week.',
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: PageView.builder(
        controller: _pager,
        scrollDirection: Axis.vertical,
        itemCount: feed.length + (_hasMore ? 1 : 0),
        onPageChanged: (i) {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
          if (i >= feed.length - 3) _fetch();
        },
        itemBuilder: (context, i) {
          if (i >= feed.length) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final scene = feed[i];
          return SpotlightEntry(
            key: ValueKey(scene.id),
            message: ThreadMessage.fromScene(scene),
            eyebrow: scene.id == sotd?.id
                ? 'Scene of the day'
                : scene.titleType.label,
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
    child: Semantics(
      header: true,
      child: Text(text, style: context.qt.sectionTitle.copyWith(fontSize: 18)),
    ),
  );
}

class _PosterRow extends StatelessWidget {
  final List<MediaTitleDto>? titles;
  final bool loading;

  const _PosterRow({required this.titles, required this.loading});

  @override
  Widget build(BuildContext context) {
    final list = titles ?? const <MediaTitleDto>[];
    if (list.isEmpty) {
      if (!loading) return const SizedBox.shrink();
      return SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) =>
              const QPoster(url: null, width: 96, height: 138, radius: 14),
        ),
      );
    }
    return SizedBox(
      // Poster + two title lines + count, with room for large text.
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => PosterCard(
          title: list[i],
          onTap: () => context.push(Routes.title(list[i].id)),
        ),
      ),
    );
  }
}

class _TypeRow extends ConsumerWidget {
  final MediaType type;
  const _TypeRow({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titles = ref.watch(trendingTitlesProvider(type.name));
    return _PosterRow(titles: titles.value, loading: titles.isLoading);
  }
}

/// Two lines from one followed title.
class _FollowedTitleLines extends ConsumerWidget {
  final String titleId;
  const _FollowedTitleLines({required this.titleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(
      sceneQuotesPageProvider(pageNumber: 1, pageSize: 2, titleId: titleId),
    );
    final list = lines.value ?? const [];
    return Column(
      children: [
        for (final l in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: MessageBubble(message: ThreadMessage.fromScene(l)),
          ),
      ],
    );
  }
}
