import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/thread/thread.dart';
import '../dtos/author_dto.dart';
import '../dtos/quote_dto.dart';
import '../navigation/routes.dart';
import '../riverpods/get_author_detail_provider.dart';
import '../services/author_page_service.dart';
import '../state_providers/recent_people.dart';
import '../state_providers/scene_state.dart';
import '../util/pagination_seed.dart';

/// An author: portrait, lifespan, bio and Follow, then "Most loved", every
/// quote (paged), and related authors at the end. Offline first: see
/// [AuthorPageService].
class AuthorDetailScreen extends ConsumerStatefulWidget {
  static const kRouteName = Routes.authorBase;

  final String authorSlug;

  const AuthorDetailScreen({super.key, required this.authorSlug});

  @override
  ConsumerState<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends ConsumerState<AuthorDetailScreen> {
  static const _pageSize = 20;

  final _scroll = ScrollController();
  final int _seed = PaginationSeed.current;

  /// Null while loading.
  List<QuoteDto>? _mostLoved;
  List<AuthorDto>? _related;

  final List<QuoteDto> _quotes = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  bool _error = false;

  /// Paging from the device (it has every quote, or the backend is out of
  /// reach). Decided on the first page.
  bool? _localMode;
  bool _recorded = false;

  String get _slug => widget.authorSlug;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 500) _fetch();
    });
    _loadMostLoved();
    _fetch();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMostLoved() async {
    List<QuoteDto> quotes;
    try {
      quotes = await AuthorPageService.mostLoved(_slug);
    } catch (e) {
      if (kDebugMode) print(e);
      quotes = const [];
    }
    if (mounted) setState(() => _mostLoved = quotes);
  }

  Future<void> _loadRelated() async {
    if (_related != null) return;
    _related = const [];
    try {
      final related = await AuthorPageService.related(_slug);
      if (mounted) setState(() => _related = related);
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final shown = {for (final q in _quotes) q.id};
      var page = (quotes: const <QuoteDto>[], fetched: 0);
      var more = false;
      if (_localMode == null) {
        final author = await ref.read(fetchAuthorDetailProvider(_slug).future);
        _localMode = AuthorPageService.localIsComplete(
          local: await AuthorPageService.localCount(_slug),
          expected: author?.quoteCount ?? 0,
        );
      }
      if (_localMode!) {
        page = await AuthorPageService.localPage(
          _slug,
          page: _page,
          pageSize: _pageSize,
          seed: _seed,
        );
        more = page.fetched == _pageSize;
      } else {
        try {
          page = await AuthorPageService.remotePage(
            _slug,
            page: _page,
            pageSize: _pageSize,
            seed: _seed,
          );
          more = page.fetched == _pageSize;
        } catch (e) {
          if (kDebugMode) print(e);
          // Offline: carry on with what this device has, minus what's shown.
          _localMode = true;
          page = await AuthorPageService.localPage(
            _slug,
            page: 1,
            pageSize: 1000,
            seed: _seed,
            skip: shown,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _hasMore = more;
        _page++;
        _quotes.addAll(page.quotes.where((q) => shown.add(q.id)));
      });
      if (!more) _loadRelated();
    } catch (e) {
      if (kDebugMode) print(e);
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _record(AuthorDto a) {
    if (_recorded) return;
    _recorded = true;
    Future.microtask(
      () => ref
          .read(recentPeopleProvider.notifier)
          .add(
            RecentPerson(
              kind: PersonKind.author,
              id: a.slug,
              name: a.name,
              imageUrl: a.imageUrl,
            ),
          ),
    );
  }

  Widget _quote(QuoteDto q, int i, AuthorDto author) => Entrance(
    key: ValueKey(q.id),
    index: i % 8,
    child: MessageBubble(
      message: ThreadMessage.fromQuote(q, senderImageUrl: author.imageUrl),
      variant: BubbleVariant.compact,
      showSender: false,
      avatarSize: 30,
    ),
  );

  Widget _quoteList(List<QuoteDto> quotes, AuthorDto author) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    sliver: SliverList.separated(
      itemCount: quotes.length,
      separatorBuilder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Divider(height: 1, color: context.q.line),
      ),
      itemBuilder: (context, i) => _quote(quotes[i], i, author),
    ),
  );

  static Widget _divider(String text) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: TimeDivider(text),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(fetchAuthorDetailProvider(_slug));
    final author = async.value;
    if (author != null) _record(author);

    return ThreadPage(
      trailing: author == null
          ? null
          : CircleIconButton(
              icon: kShareIcon,
              semanticLabel: 'Share ${author.name}',
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text: 'Quotes by ${author.name}, on Quotely',
                  sharePositionOrigin: const Rect.fromLTRB(0, 0, 1, 1),
                ),
              ),
            ),
      body: async.isLoading && author == null
          ? const DetailSkeleton(poster: false)
          : author == null
          ? ErrorBubble(
              message: 'Failed to get author detail.',
              onRetry: () => ref.invalidate(fetchAuthorDetailProvider(_slug)),
            )
          : _body(author),
    );
  }

  Widget _body(AuthorDto author) {
    final loved = _mostLoved;
    final lovedIds = {for (final q in loved ?? const <QuoteDto>[]) q.id};
    // "All quotes" waits for Most loved so a quote never jumps between them.
    final rest = loved == null
        ? const <QuoteDto>[]
        : [
            for (final q in _quotes)
              if (!lovedIds.contains(q.id)) q,
          ];
    final nothing =
        loved != null && loved.isEmpty && _quotes.isEmpty && !_hasMore;
    final related = _related ?? const <AuthorDto>[];

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(child: _Profile(author: author)),
        if (loved != null && loved.isNotEmpty) ...[
          _divider('Most loved'),
          _quoteList(loved, author),
        ],
        if (rest.isNotEmpty) ...[
          _divider(loved!.isEmpty ? 'Quotes' : 'All quotes'),
          _quoteList(rest, author),
        ],
        SliverToBoxAdapter(
          child: _error && _quotes.isEmpty && (loved?.isEmpty ?? true)
              ? ErrorBubble(message: 'Failed to get quotes.', onRetry: _fetch)
              : _loading || loved == null
              ? const LoadMoreIndicator()
              : nothing
              ? EmptyState(pill: 'No quotes by ${author.name} yet')
              : const SizedBox(height: 8),
        ),
        if (!_hasMore && related.isNotEmpty) ...[
          _divider('Related'),
          SliverToBoxAdapter(child: _Related(authors: related)),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _Profile extends ConsumerWidget {
  final AuthorDto author;
  const _Profile({required this.author});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final following = ref.watch(
      followedAuthorsProvider.select((s) => s.contains(author.slug)),
    );
    final lifespan = AuthorLifespan.of(author);
    Widget pill(
      String text, {
      bool filled = false,
      VoidCallback? onTap,
      IconData? icon,
    }) {
      final child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? t.ink : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: filled ? t.ink : t.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: context.qt.chip.copyWith(
                fontWeight: FontWeight.w600,
                color: filled ? t.bg : t.ink,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: filled ? t.bg : t.ink),
            ],
          ],
        ),
      );
      return onTap == null
          ? child
          : Semantics(
              button: true,
              label: text,
              excludeSemantics: true,
              child: Pressable(onTap: onTap, child: child),
            );
    }

    final link = author.link.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          QAvatar(
            name: author.name,
            imageUrl: author.imageUrl,
            size: 88,
            heroTag: author.slug,
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              author.name,
              textAlign: TextAlign.center,
              style: context.qt.titlePush,
            ),
          ),
          if (author.description.isNotEmpty || lifespan != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (author.description.isNotEmpty) author.description,
                ?lifespan,
              ].join(' · '),
              textAlign: TextAlign.center,
              style: context.qt.meta,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Semantics(
                toggled: following,
                child: pill(
                  following ? '✓ Following' : 'Follow',
                  filled: !following,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(followedAuthorsProvider.notifier)
                        .toggle(author.slug);
                  },
                ),
              ),
              pill(
                author.quoteCount == 1
                    ? '1 quote'
                    : '${author.quoteCount} quotes',
              ),
              if (link.isNotEmpty)
                pill(
                  'Wiki',
                  icon: Icons.north_east_rounded,
                  onTap: () async {
                    final uri = Uri.tryParse(link);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
            ],
          ),
          if (author.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Bio(text: author.bio),
          ],
        ],
      ),
    );
  }
}

/// A short biography: four lines, then "More" if there is more.
class _Bio extends StatefulWidget {
  final String text;
  const _Bio({required this.text});

  @override
  State<_Bio> createState() => _BioState();
}

class _BioState extends State<_Bio> {
  static const _lines = 4;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = context.qt.body.copyWith(height: 1.5);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _lines,
          textAlign: TextAlign.center,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final long = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                maxLines: _open ? null : _lines,
                overflow: _open ? null : TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (long)
              QTextButton(
                label: _open ? 'Less' : 'More',
                color: context.q.accInk,
                onPressed: () => setState(() => _open = !_open),
              ),
          ],
        );
      },
    );
  }
}

/// Authors who share this one's subjects, as story avatars.
class _Related extends StatelessWidget {
  final List<AuthorDto> authors;
  const _Related({required this.authors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: authors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final a = authors[i];
          return StoryAvatar(
            name: a.name.split(' ').last,
            imageUrl: a.imageUrl,
            isNew: false,
            onTap: () => context.push(Routes.author(a.slug)),
          );
        },
      ),
    );
  }
}
