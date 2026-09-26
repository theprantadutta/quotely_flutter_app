import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/thread/thread.dart';
import '../dtos/author_dto.dart';
import '../dtos/quote_dto.dart';
import '../navigation/routes.dart';
import '../riverpods/all_quotes_by_author_provider.dart';
import '../riverpods/get_author_detail_provider.dart';
import '../state_providers/recent_people.dart';
import '../state_providers/scene_state.dart';
import '../util/pagination_seed.dart';

class AuthorDetailScreen extends ConsumerStatefulWidget {
  static const kRouteName = Routes.authorBase;

  final String authorSlug;

  const AuthorDetailScreen({super.key, required this.authorSlug});

  @override
  ConsumerState<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends ConsumerState<AuthorDetailScreen> {
  final _scroll = ScrollController();
  final List<QuoteDto> _quotes = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  bool _error = false;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 500) _fetch();
    });
    _fetch();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final res = await ref.read(
        fetchAllQuotesByAuthorProvider(
          widget.authorSlug,
          _page,
          10,
          PaginationSeed.current,
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _hasMore = res.quotes.length == 10;
        _page++;
        _quotes.addAll(
          res.quotes.where((q) => !_quotes.any((x) => x.id == q.id)),
        );
      });
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(fetchAuthorDetailProvider(widget.authorSlug));
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
              onRetry: () =>
                  ref.invalidate(fetchAuthorDetailProvider(widget.authorSlug)),
            )
          : CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(child: _Profile(author: author)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 22, bottom: 12),
                    child: TimeDivider('Most loved'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  sliver: SliverList.separated(
                    itemCount: _quotes.length,
                    separatorBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Divider(height: 1, color: context.q.line),
                    ),
                    itemBuilder: (context, i) => Entrance(
                      key: ValueKey(_quotes[i].id),
                      index: i % 8,
                      child: MessageBubble(
                        message: ThreadMessage.fromQuote(
                          _quotes[i],
                          senderImageUrl: author.imageUrl,
                        ),
                        variant: BubbleVariant.compact,
                        showSender: false,
                        avatarSize: 30,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _error && _quotes.isEmpty
                      ? ErrorBubble(
                          message: 'Failed to get quotes.',
                          onRetry: _fetch,
                        )
                      : _loading
                      ? const LoadMoreIndicator()
                      : _quotes.isEmpty
                      ? EmptyState(pill: 'No quotes by ${author.name} yet')
                      : const SizedBox(height: 32),
                ),
              ],
            ),
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
          if (author.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              author.description,
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
              pill('${author.quoteCount} quotes'),
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
            Text(
              author.bio,
              textAlign: TextAlign.center,
              style: context.qt.body.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
