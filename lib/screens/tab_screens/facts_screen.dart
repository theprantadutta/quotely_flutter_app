import 'dart:convert';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../components/thread/thread.dart';
import '../../constants/shared_preference_keys.dart';
import '../../dtos/ai_fact_dto.dart';
import '../../navigation/routes.dart';
import '../../riverpods/all_facts_categories_data_provider.dart';
import '../../riverpods/all_facts_data_provider.dart';
import '../../service_locator/init_service_locators.dart';
import '../../state_providers/user_interests.dart';
import '../../util/pagination_seed.dart';

/// Forces Play on even before any fact has a false variant. Off: Play shows
/// up by itself once the backend's GenerateFactFalseVariantsJob has filled
/// them in (a "True" only game would always be "True").
const bool kFactsGameEnabled = false;

/// Questions per day in Play.
const int kFactsPerDay = 10;

enum _FactsMode { play, browse }

class FactsScreen extends ConsumerStatefulWidget {
  static const kRouteName = Routes.facts;
  const FactsScreen({super.key});

  @override
  ConsumerState<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends ConsumerState<FactsScreen> {
  final analytics = getIt.get<FirebaseAnalytics>();
  final _scroll = ScrollController();
  final _random = Random();

  _FactsMode _mode = _FactsMode.browse;
  bool _userPickedMode = false;
  String? _category;

  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _error = false;
  final List<AiFactDto> _facts = [];

  // Play deals from its own list: only facts that have a false twin.
  final List<AiFactDto> _playFacts = [];
  int _playPage = 1;
  bool _playHasMore = true;
  bool _playLoading = false;
  int _playRetries = 0;
  bool _ignoreInterests = false;
  bool _initialLoadDone = false;
  List<String> _appliedInterests = const [];

  // Play state
  int _answered = 0;
  int _correct = 0;
  int _deckIndex = 0;
  bool _showingFalse = false;
  bool? _lastAnswerRight;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 500) _fetch();
    });
    _loadProgress();
    _loadInitial();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await ref.read(userInterestsProvider.notifier).ready;
    if (!mounted) return;
    _appliedInterests = List.of(ref.read(userInterestsProvider));
    await Future.wait([_fetch(), _fetchPlay()]);
    if (mounted) setState(() => _initialLoadDone = true);
  }

  // --- Daily progress --------------------------------------------------------

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kFactsGameProgressKey);
    if (raw == null) return;
    final j = json.decode(raw) as Map<String, dynamic>;
    if (j['date'] != _today || !mounted) return;
    setState(() {
      _answered = j['answered'] as int? ?? 0;
      _correct = j['correct'] as int? ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kFactsGameProgressKey,
      json.encode({'date': _today, 'answered': _answered, 'correct': _correct}),
    );
  }

  // --- Data -----------------------------------------------------------------

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    if (_page > 1) {
      analytics.logEvent(
        name: 'facts_paginated',
        parameters: {'page_number': _page},
      );
    }
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final interests = ref.read(userInterestsProvider);
      final categories = _category != null
          ? [_category!]
          : (_ignoreInterests ? const <String>[] : interests);
      var res = await ref.read(
        fetchAllFactsProvider(
          _page,
          10,
          categories,
          const [],
          PaginationSeed.current,
        ).future,
      );
      if (res.aiFacts.isEmpty &&
          _page == 1 &&
          _category == null &&
          categories.isNotEmpty) {
        _ignoreInterests = true;
        res = await ref.read(
          fetchAllFactsProvider(
            1,
            10,
            const [],
            const [],
            PaginationSeed.current,
          ).future,
        );
      }
      if (!mounted) return;
      setState(() {
        _hasMore = res.aiFacts.length == 10;
        _page++;
        _facts.addAll(
          res.aiFacts.where((f) => !_facts.any((x) => x.id == f.id)),
        );
        // Switch to Play the first time playable facts show up, unless the
        // user already chose a mode.
        if (!_userPickedMode && _gameAvailable) _mode = _FactsMode.play;
        _shuffleCurrent();
      });
    } catch (e) {
      if (kDebugMode) print(e);
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchPlay() async {
    if (_playLoading || !_playHasMore) return;
    _playLoading = true;
    try {
      final res = await ref.read(
        fetchAllFactsProvider(
          _playPage,
          10,
          _category == null ? const <String>[] : [_category!],
          const [],
          PaginationSeed.current,
          playable: true,
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _playHasMore = res.aiFacts.length == 10;
        _playPage++;
        _playFacts.addAll(
          res.aiFacts.where(
            (f) =>
                (f.falseVariant ?? '').trim().isNotEmpty &&
                !_playFacts.any((x) => x.id == f.id),
          ),
        );
        if (!_userPickedMode && _gameAvailable) _mode = _FactsMode.play;
        _shuffleCurrent();
      });
    } catch (e) {
      if (kDebugMode) print(e);
      // A dropped request shouldn't hide the game for the whole session:
      // try again shortly (and on every refresh). The failed call is cached
      // by the keep-alive provider, so drop it first.
      _playRetries++;
      if (_playRetries <= 3) {
        Future.delayed(Duration(seconds: 2 * _playRetries), () {
          if (!mounted) return;
          ref.invalidate(fetchAllFactsProvider);
          _fetchPlay();
        });
      }
    } finally {
      _playLoading = false;
    }
  }

  void _resetPlay() {
    _playFacts.clear();
    _playPage = 1;
    _playHasMore = true;
    _playRetries = 0;
  }

  Future<void> _refresh() async {
    ref.invalidate(fetchAllFactsProvider);
    setState(() {
      _facts.clear();
      _page = 1;
      _hasMore = true;
      _deckIndex = 0;
      _lastAnswerRight = null;
      _resetPlay();
    });
    await Future.wait([_fetch(), _fetchPlay()]);
  }

  void _setCategory(String? c) {
    setState(() {
      _category = c;
      _facts.clear();
      _page = 1;
      _hasMore = true;
      _deckIndex = 0;
      _lastAnswerRight = null;
      _ignoreInterests = false;
      _resetPlay();
    });
    ref.invalidate(fetchAllFactsProvider);
    _fetch();
    _fetchPlay();
  }

  List<AiFactDto> get _deck => _playFacts;

  bool get _gameAvailable => kFactsGameEnabled || _deck.isNotEmpty;

  AiFactDto? get _current {
    final deck = kFactsGameEnabled && _deck.isEmpty ? _facts : _deck;
    if (_deckIndex >= deck.length) return null;
    return deck[_deckIndex];
  }

  /// Decide once per question whether the true or false statement is shown.
  void _shuffleCurrent() {
    final f = _current;
    _showingFalse =
        f != null &&
        (f.falseVariant ?? '').trim().isNotEmpty &&
        _random.nextBool();
  }

  void _answer(bool saidTrue) {
    if (_lastAnswerRight != null) return;
    final right = saidTrue != _showingFalse;
    HapticFeedback.lightImpact();
    setState(() {
      _lastAnswerRight = right;
      _answered++;
      if (right) _correct++;
    });
    _saveProgress();
    analytics.logEvent(
      name: 'facts_game_answered',
      parameters: {
        'correct': right.toString(),
        'category': _current?.aiFactCategory ?? '',
      },
    );
  }

  void _next() {
    setState(() {
      _deckIndex++;
      _lastAnswerRight = null;
      _shuffleCurrent();
    });
    if (_deckIndex >= _deck.length - 2) _fetchPlay();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userInterestsProvider, (previous, next) {
      if (!_initialLoadDone || listEquals(_appliedInterests, next)) return;
      _appliedInterests = List.of(next);
      if (_category != null) return;
      _refresh();
    });

    final categories =
        ref.watch(fetchAllFactsCategoriesProvider).value ?? const <String>[];
    final play = _mode == _FactsMode.play && _gameAvailable;
    final subtitle = play
        ? '${min(_answered, kFactsPerDay)} of $kFactsPerDay today · $_correct right so far'
        : 'Strange, true and worth knowing';

    return SafeArea(
      bottom: false,
      child: ThreadColumn(
        child: Column(
          children: [
            ScreenHeader(
              title: play ? 'True or false?' : 'Facts',
              subtitle: subtitle,
              actions: [
                if (_gameAvailable)
                  MiniSegmented<_FactsMode>(
                    options: const [
                      ChipOption(_FactsMode.play, 'Play'),
                      ChipOption(_FactsMode.browse, 'Browse'),
                    ],
                    value: _mode,
                    onChanged: (m) => setState(() {
                      _mode = m;
                      _userPickedMode = true;
                    }),
                  ),
              ],
            ),
            if (categories.isNotEmpty)
              FilterChips<String?>(
                options: [
                  const ChipOption(null, 'All'),
                  for (final c in categories)
                    if (c.isNotEmpty) ChipOption(c, c),
                ],
                isSelected: (c) => c == _category,
                onSelected: _setCategory,
              ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: _refresh,
                child: play ? _buildPlay() : _buildBrowse(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowse() {
    return CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          sliver: SliverList.separated(
            itemCount: _facts.length,
            separatorBuilder: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Divider(height: 1, color: context.q.line),
            ),
            itemBuilder: (context, i) => Entrance(
              key: ValueKey(_facts[i].id),
              index: i % 8,
              child: MessageBubble(
                message: ThreadMessage.fromFact(_facts[i]),
                senderLabel: _facts[i].aiFactCategory,
                variant: BubbleVariant.compact,
                showReactions: true,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _footer()),
      ],
    );
  }

  Widget _footer() {
    if (_error && _facts.isEmpty) {
      return ErrorBubble(message: 'Failed to get facts.', onRetry: _fetch);
    }
    if (_loading || !_initialLoadDone) {
      return _facts.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ThreadSkeleton(count: 3),
            )
          : const LoadMoreIndicator();
    }
    if (_facts.isEmpty) {
      return EmptyState(
        pill: 'No facts found',
        action: SecondaryButton(
          label: 'Try again',
          expand: false,
          onPressed: _refresh,
        ),
      );
    }
    return const SizedBox(height: 24);
  }

  /// "Keep" on the back of the card: save it, then deal the next one.
  Future<void> _keep(AiFactDto fact) async {
    final m = ThreadMessage.fromFact(fact);
    if (!readIsSaved(ref, m)) await toggleSaved(ref, m);
    if (mounted) _next();
  }

  Widget _buildPlay() {
    final fact = _current;
    if (fact == null) {
      return ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [_loading ? const FactCardSkeleton() : _footer()],
      );
    }
    final answered = _lastAnswerRight != null;
    final done = _answered == kFactsPerDay && answered;
    final shown = _showingFalse ? fact.falseVariant! : fact.content;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
      child: Column(
        children: [
          SegmentedProgress(
            total: kFactsPerDay,
            done: min(_answered, kFactsPerDay),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 430),
                child: _Flip(
                  key: ValueKey('${fact.id}:$_deckIndex'),
                  flipped: answered,
                  front: _FactFace(
                    eyebrow: fact.aiFactCategory,
                    child: Semantics(
                      liveRegion: true,
                      child: Text(shown, style: _factStyle(context, shown)),
                    ),
                  ),
                  back: _AnswerFace(
                    fact: fact,
                    right: _lastAnswerRight ?? false,
                    wasFalse: _showingFalse,
                    footnote: done
                        ? 'That\u2019s today\u2019s $kFactsPerDay. $_correct right. See you tomorrow.'
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (!answered)
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'False',
                    onPressed: () => _answer(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'True',
                    onPressed: () => _answer(true),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(label: 'Skip', onPressed: _next),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Keep',
                    icon: Icons.favorite_border_rounded,
                    onPressed: () => _keep(fact),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The fact at a size that fits its length: short facts go large, long
/// ones step down so it never turns into a wall of text.
TextStyle _factStyle(BuildContext context, String text) {
  final base = context.qt.quoteFact;
  final n = text.length;
  final f = n <= 90
      ? 1.05
      : n <= 150
      ? 0.95
      : n <= 230
      ? 0.84
      : n <= 330
      ? 0.74
      : 0.64;
  return base.copyWith(fontSize: base.fontSize! * f, height: 1.18);
}

/// Turns [front] over (around the vertical axis) to [back] when [flipped].
/// No card behind it: the fact sits on the page like Today's lines.
class _Flip extends StatelessWidget {
  final bool flipped;
  final Widget front;
  final Widget back;

  const _Flip({
    super.key,
    required this.flipped,
    required this.front,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? pi : 0),
      duration: context.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      builder: (context, angle, _) {
        final showBack = angle > pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: back,
                )
              : front,
        );
      },
    );
  }
}

/// One side of the fact: category overline at the top, the text centred
/// in the space, an optional footer at the bottom.
class _FactFace extends StatelessWidget {
  final String eyebrow;
  final Widget child;
  final Widget? footer;

  const _FactFace({required this.eyebrow, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: context.qt.overline),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(child: child),
            ),
          ),
          ?footer,
        ],
      ),
    );
  }
}

/// The back: the verdict, the real fact, and Share.
class _AnswerFace extends StatelessWidget {
  final AiFactDto fact;
  final bool right;
  final bool wasFalse;
  final String? footnote;

  const _AnswerFace({
    required this.fact,
    required this.right,
    required this.wasFalse,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    final verdict = wasFalse ? 'false' : 'true';
    final body = _factStyle(context, fact.content);
    return Semantics(
      liveRegion: true,
      child: _FactFace(
        eyebrow: wasFalse ? 'The real fact' : fact.aiFactCategory,
        footer: Row(
          children: [
            Expanded(child: Text(footnote ?? '', style: qt.meta)),
            CircleIconButton(
              icon: kShareIcon,
              semanticLabel: 'Share',
              foreground: t.mute,
              onTap: () => shareMessage(ThreadMessage.fromFact(fact)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              right
                  ? 'You got it \u2014 it\u2019s $verdict.'
                  : 'Not quite \u2014 it\u2019s $verdict.',
              style: qt.sectionTitle,
            ),
            const SizedBox(height: 16),
            Text(
              fact.content,
              style: body.copyWith(
                fontSize: body.fontSize! * 0.82,
                color: t.ink.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
