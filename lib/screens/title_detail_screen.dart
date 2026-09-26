import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../components/thread/thread.dart';
import '../dtos/character_dto.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/scene_quote_dto.dart';
import '../riverpods/scene_providers.dart';
import '../services/drift_scene_service.dart';
import '../state_providers/scene_state.dart';

/// A movie / show / anime / game page: follow it, filter by character,
/// read its lines with the spoiler shield applied.
class TitleDetailScreen extends ConsumerStatefulWidget {
  final String titleId;

  /// A line to pin at the top (opened from a notification or a bubble).
  final String? focusQuoteId;
  final String? focusCharacterId;

  const TitleDetailScreen({
    super.key,
    required this.titleId,
    this.focusQuoteId,
    this.focusCharacterId,
  });

  @override
  ConsumerState<TitleDetailScreen> createState() => _TitleDetailScreenState();
}

class _TitleDetailScreenState extends ConsumerState<TitleDetailScreen> {
  final _scroll = ScrollController();
  late String? _characterId = widget.focusCharacterId;
  String _sort = 'popular';
  final List<SceneQuoteDto> _lines = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  SceneQuoteDto? _focus;
  bool _highlight = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 500) _fetch();
    });
    _fetch();
    if (widget.focusQuoteId != null) {
      DriftSceneService.getById(widget.focusQuoteId!).then((q) {
        if (mounted) setState(() => _focus = q);
      });
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _highlight = false);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = await ref.read(
        sceneQuotesPageProvider(
          pageNumber: _page,
          pageSize: 20,
          titleId: widget.titleId,
          characterId: _characterId,
          sort: _sort,
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _hasMore = page.length == 20;
        _page++;
        _lines.addAll(page.where((l) => !_lines.any((x) => x.id == l.id)));
      });
    } catch (_) {
      _hasMore = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset({
    String? characterId,
    String? sort,
    bool clearCharacter = false,
  }) {
    setState(() {
      if (clearCharacter) {
        _characterId = null;
      } else if (characterId != null) {
        _characterId = characterId;
      }
      if (sort != null) _sort = sort;
      _lines.clear();
      _page = 1;
      _hasMore = true;
    });
    _fetch();
  }

  Future<void> _showMore(MediaTitleDto title) async {
    final watched = ref.read(watchedUpToProvider)[title.id];
    await showQSheet(
      context,
      builder: (sheet) => QSheetFrame(
        child: Column(
          children: [
            SheetAction(
              icon: kShareIcon,
              label: 'Share title',
              onTap: () {
                Navigator.of(sheet).pop();
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${title.name} (${title.yearsLabel}) · lines on Quotely',
                    sharePositionOrigin: const Rect.fromLTRB(0, 0, 1, 1),
                  ),
                );
              },
            ),
            if (title.type == MediaType.tv ||
                title.type == MediaType.anime ||
                title.type == MediaType.cartoon)
              SheetAction(
                icon: Icons.visibility_outlined,
                label: watched == null
                    ? 'I’ve watched up to episode…'
                    : 'Watched up to episode $watched',
                onTap: () {
                  Navigator.of(sheet).pop();
                  _askWatched(title, watched);
                },
              ),
            SheetAction(
              icon: Icons.flag_outlined,
              label: 'Report a problem with this title',
              onTap: () {
                Navigator.of(sheet).pop();
                final first = _lines.isNotEmpty ? _lines.first : _focus;
                if (first != null) {
                  showReportSheet(context, ThreadMessage.fromScene(first));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askWatched(MediaTitleDto title, int? current) async {
    final controller = TextEditingController(text: current?.toString() ?? '');
    await showQSheet(
      context,
      builder: (sheet) => QSheetFrame(
        title: 'How far have you watched?',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Spoilers up to this episode will show without the blur. '
              'Count episodes from the very first one.',
              style: sheet.qt.body,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'Episode number'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: current == null ? 'Cancel' : 'Clear',
                    onPressed: () {
                      if (current != null) {
                        ref
                            .read(watchedUpToProvider.notifier)
                            .set(title.id, null);
                      }
                      Navigator.of(sheet).pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Save',
                    height: 52,
                    onPressed: () {
                      final n = int.tryParse(controller.text);
                      ref.read(watchedUpToProvider.notifier).set(title.id, n);
                      Navigator.of(sheet).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  String _senderLabel(SceneQuoteDto l, bool hidden) {
    final ep = l.episodeLabel;
    if (hidden) return ep == null ? 'Spoiler' : 'Spoiler · $ep';
    return ep == null ? l.characterName : '${l.characterName} · $ep';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final async = ref.watch(titleDetailProvider(widget.titleId));
    final detail = async.value;
    final shield = ref.watch(spoilerShieldProvider);
    // The pinned line isn't repeated in the list below it.
    final pinned = _focus != null && _characterId == null;
    final lines = pinned
        ? _lines.where((l) => l.id != _focus!.id).toList()
        : _lines;

    return ThreadPage(
      trailing: detail == null
          ? null
          : CircleIconButton(
              icon: Icons.more_horiz_rounded,
              semanticLabel: 'More',
              onTap: () => _showMore(detail.title),
            ),
      body: detail == null
          ? (async.isLoading
                ? const DetailSkeleton()
                : ErrorBubble(
                    message: 'We couldn’t find that title.',
                    onRetry: () =>
                        ref.invalidate(titleDetailProvider(widget.titleId)),
                  ))
          : CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(child: _Hero(title: detail.title)),
                if (detail.characters.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _Characters(
                      characters: detail.characters,
                      selected: _characterId,
                      onTap: (c) => c.id == _characterId
                          ? _reset(clearCharacter: true)
                          : _reset(characterId: c.id),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilterChips<String>(
                            options: [
                              const ChipOption('popular', 'Most loved'),
                              if (detail.title.type == MediaType.tv ||
                                  detail.title.type == MediaType.anime ||
                                  detail.title.type == MediaType.cartoon)
                                const ChipOption('episode', 'By episode')
                              else
                                const ChipOption('episode', 'In order'),
                            ],
                            isSelected: (s) => s == _sort,
                            onSelected: (s) => _reset(sort: s),
                          ),
                        ),
                        Semantics(
                          toggled: shield,
                          label: 'Spoiler shield',
                          excludeSemantics: true,
                          child: HitTarget(
                            onTap: () => ref
                                .read(spoilerShieldProvider.notifier)
                                .toggle(),
                            child: Text(
                              shield ? 'Shield on' : 'Shield off',
                              style: context.qt.caption.copyWith(
                                color: shield ? t.accInk : t.mute,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (pinned)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _highlight ? t.acc : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: MessageBubble(
                          message: ThreadMessage.fromScene(_focus!),
                          showAvatar: false,
                          showTitleChip: false,
                          showReactions: true,
                          senderLabel: _senderLabel(
                            _focus!,
                            isSpoilerHidden(ref, _focus!),
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  sliver: SliverList.separated(
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Divider(height: 1, color: context.q.line),
                    ),
                    itemBuilder: (context, i) {
                      final l = lines[i];
                      return Entrance(
                        key: ValueKey(l.id),
                        index: i % 8,
                        child: MessageBubble(
                          message: ThreadMessage.fromScene(l),
                          showAvatar: false,
                          showTitleChip: false,
                          variant: BubbleVariant.regular,
                          senderLabel: _senderLabel(l, isSpoilerHidden(ref, l)),
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _loading
                      ? const LoadMoreIndicator()
                      : _lines.isEmpty
                      ? const EmptyState(pill: 'No lines yet')
                      : const SizedBox(height: 32),
                ),
              ],
            ),
    );
  }
}

class _Hero extends ConsumerWidget {
  final MediaTitleDto title;
  const _Hero({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final following = ref.watch(
      followedTitlesProvider.select((m) => m.containsKey(title.id)),
    );
    final meta = [
      title.yearsLabel,
      ?title.primaryGenre,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QPoster(url: title.posterUrl, width: 92, height: 132, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SoftPill(title.type.label, fontSize: 12),
                    const SizedBox(height: 10),
                    Semantics(
                      header: true,
                      child: Text(title.name, style: context.qt.titleDetail),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      style: context.qt.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Semantics(
                          button: true,
                          toggled: following,
                          label: following ? 'Following' : 'Follow',
                          excludeSemantics: true,
                          child: Pressable(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(followedTitlesProvider.notifier)
                                  .toggle(title);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: following ? null : t.ink,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: t.ink),
                              ),
                              child: Text(
                                following ? '✓ Following' : 'Follow',
                                style: context.qt.chip.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: following ? t.ink : t.bg,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: t.line),
                          ),
                          child: Text(
                            '${title.quoteCount} quotes',
                            style: context.qt.chip.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (title.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(title.description, style: context.qt.body),
          ],
        ],
      ),
    );
  }
}

class _Characters extends StatelessWidget {
  final List<CharacterDto> characters;
  final String? selected;
  final ValueChanged<CharacterDto> onTap;

  const _Characters({
    required this.characters,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: characters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = characters[i];
          final isSelected = c.id == selected;
          return Semantics(
            selected: isSelected,
            button: true,
            label: 'Show lines by ${c.name}',
            excludeSemantics: true,
            child: Pressable(
              onTap: () => onTap(c),
              child: SizedBox(
                width: 64,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? t.acc : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: QAvatar(
                        name: c.name,
                        imageUrl: c.avatarUrl,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      c.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: context.qt.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? t.accInk : t.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
