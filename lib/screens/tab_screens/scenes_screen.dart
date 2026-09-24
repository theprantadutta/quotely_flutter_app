import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/thread/thread.dart';
import '../../dtos/media_title_dto.dart';
import '../../dtos/scene_quote_dto.dart';
import '../../navigation/routes.dart';
import '../../riverpods/scene_providers.dart';
import '../../service_locator/init_service_locators.dart';
import '../../state_providers/scene_state.dart';

/// Scenes: lines from movies, shows, anime and games.
class ScenesScreen extends ConsumerStatefulWidget {
  const ScenesScreen({super.key});

  @override
  ConsumerState<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends ConsumerState<ScenesScreen> {
  final _scroll = ScrollController();

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
    });
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
    final followed = ref.watch(followedTitlesProvider);
    final trending = ref.watch(trendingTitlesProvider(_typesCsv));

    return SafeArea(
      bottom: false,
      child: ThreadColumn(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Scenes',
              subtitle: 'Lines from movies, shows, anime & games',
              actions: [
                CircleIconButton(
                  icon: Icons.search_rounded,
                  semanticLabel: 'Search titles',
                  onTap: () => context.push(Routes.search),
                ),
              ],
            ),
            FilterChips<MediaType?>(
              options: [
                const ChipOption(null, 'All'),
                for (final t in MediaType.values) ChipOption(t, t.plural),
              ],
              isSelected: (t) => t == _type,
              onSelected: _setType,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                      sliver: SliverToBoxAdapter(child: _SceneOfTheDayCard()),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Trending titles',
                                style: context.qt.sectionTitle.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Semantics(
                              toggled: shield,
                              label: 'Spoiler shield',
                              excludeSemantics: true,
                              child: SoftPill(
                                shield
                                    ? 'Spoiler shield on'
                                    : 'Spoiler shield off',
                                icon: shield
                                    ? Icons.shield_rounded
                                    : Icons.shield_outlined,
                                onTap: () => ref
                                    .read(spoilerShieldProvider.notifier)
                                    .toggle(),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    const SliverToBoxAdapter(
                      child: _SectionTitle('Popular lines'),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: _lines.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => Entrance(
                          key: ValueKey(_lines[i].id),
                          index: i % 8,
                          child: MessageBubble(
                            message: ThreadMessage.fromScene(_lines[i]),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _loading
                          ? (_lines.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: ThreadSkeleton(count: 2),
                                  )
                                : const LoadMoreIndicator())
                          : _lines.isEmpty
                          ? EmptyState(
                              pill: 'No lines here yet',
                              message: _type == null
                                  ? 'New scenes arrive every week.'
                                  : 'No ${_type!.plural.toLowerCase()} yet. New scenes arrive every week.',
                            )
                          : const SizedBox(height: 24),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

/// "SCENE OF THE DAY": poster + title block, the line, character, reactions.
class _SceneOfTheDayCard extends ConsumerWidget {
  const _SceneOfTheDayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final async = ref.watch(sceneOfTheDayProvider);
    final dto = async.value;
    if (dto == null) {
      return async.isLoading
          ? const BubbleSkeleton(avatar: false, width: 1, lines: 3)
          : const SizedBox.shrink();
    }
    final scene = dto.sceneQuote;
    final message = ThreadMessage.fromScene(scene);
    final hidden = isSpoilerHidden(ref, scene);
    // Genre lives on the title, not the line (line tags are topics).
    final genre = ref
        .watch(titleDetailProvider(scene.titleId))
        .value
        ?.title
        .primaryGenre;
    return Pressable(
      pressedScale: 0.985,
      onTap: () => openSender(context, message),
      onLongPress: () => showMessageActions(context, ref, message),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surf,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                QPoster(url: scene.posterUrl, width: 44, height: 64, radius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCENE OF THE DAY',
                        style: context.qt.caption.copyWith(
                          color: t.accInk,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 11 * 0.04,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        scene.titleName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.qt.rowTitle.copyWith(fontSize: 16),
                      ),
                      Text(
                        [scene.chipMeta, ?genre].join(' · '),
                        style: context.qt.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SpoilerBubble(
              hidden: hidden,
              onReveal: () =>
                  ref.read(revealedSpoilersProvider.notifier).reveal(scene.id),
              radius: BorderRadius.circular(12),
              child: Text(scene.content, style: context.qt.quoteFeature),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '— ${scene.characterName}',
                    style: context.qt.meta.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final saved = watchIsSaved(ref, message);
                    return ReactionPill.like(
                      liked: saved,
                      count: scene.likes + (saved ? 1 : 0),
                      onTap: () => toggleSaved(ref, message),
                    );
                  },
                ),
                const SizedBox(width: 4),
                CircleIconButton(
                  icon: kShareIcon,
                  semanticLabel: 'Share',
                  size: 38,
                  background: t.bg,
                  onTap: () => shareMessage(message),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
      height: 196,
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
