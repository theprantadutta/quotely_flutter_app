import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/home_screen/ios_update_banner.dart';
import '../../components/home_screen/topics_row.dart';
import '../../components/thread/thread.dart';
import '../../constants/selectors.dart';
import '../../dtos/ai_fact_dto.dart';
import '../../dtos/of_the_day_adapters.dart';
import '../../dtos/quote_dto.dart';
import '../../dtos/scene_quote_dto.dart';
import '../../main.dart';
import '../../navigation/routes.dart';
import '../../notifications/push_notification.dart';
import '../../riverpods/all_facts_data_provider.dart';
import '../../riverpods/all_quote_data_provider.dart';
import '../../riverpods/daily_brain_food_provider.dart';
import '../../riverpods/daily_inspiration_provider.dart';
import '../../riverpods/motivation_monday_provider.dart';
import '../../riverpods/scene_providers.dart';
import '../../riverpods/today_fact_of_the_day_provider.dart';
import '../../riverpods/today_quote_of_the_day_provider.dart';
import '../../riverpods/weird_fact_wednesday_provider.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/activity_service.dart';
import '../../services/composer_search_service.dart';
import '../../services/drift_fact_service.dart';
import '../../services/drift_quote_service.dart';
import '../../services/drift_scene_service.dart';
import '../../state_providers/favorite_fact_ids.dart';
import '../../state_providers/favorite_quote_ids.dart';
import '../../state_providers/profile.dart';
import '../../state_providers/scene_state.dart';
import '../../state_providers/user_interests.dart';
import '../../util/pagination_seed.dart';

enum TodayFilter { all, quotes, scenes, facts }

/// One composer exchange: the user's prompt and Quotely's answer.
class _Ask {
  final String prompt;
  List<ThreadMessage>? answers;
  _Ask(this.prompt);
}

/// Today: the daily thread. Today's deliveries (quote of the day, scene,
/// fact prompt…) grouped under time dividers, then an endless feed.
class HomeScreen extends ConsumerStatefulWidget {
  static const kRouteName = Routes.today;
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final analytics = getIt.get<FirebaseAnalytics>();
  final _scroll = ScrollController();
  TodayFilter _filter = TodayFilter.all;

  // --- Quote feed (same paging + interest fallback as the old Home) -------
  int quotePageNumber = 1;
  final int quotePageSize = kHomeQuotePageSize;
  bool hasMoreData = true;
  bool hasError = false;
  bool isLoadingMore = false;
  List<QuoteDto> quotes = [];
  final List<String> allSelectedTags = [];
  bool _ignoreInterestsForQuotes = false;
  List<String> _appliedInterests = const [];
  bool _initialLoadDone = false;

  // --- Scene feed ----------------------------------------------------------
  final List<SceneQuoteDto> _scenes = [];
  int _scenePage = 1;
  bool _scenesLoading = false;
  bool _scenesHasMore = true;

  // --- Fact feed (Facts filter) ---------------------------------------------
  final List<AiFactDto> _facts = [];
  int _factPage = 1;
  bool _factsLoading = false;
  bool _factsHasMore = true;
  bool _ignoreInterestsForFacts = false;

  // --- Composer --------------------------------------------------------------
  final List<_Ask> _asks = [];
  bool _asking = false;

  int _streak = 0;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _scroll.addListener(_onScroll);
    _loadInitialQuotes();
    _loadFavoriteIds();
    _fetchScenes();
    ActivityService.instance.summary().then((s) {
      if (mounted) setState(() => _streak = s.streak);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showLegalConsentIfNeeded(context);
      await PushNotifications.asyncQueue.start();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels < pos.maxScrollExtent - 600) return;
    switch (_filter) {
      case TodayFilter.all:
        _fetchQuotes();
        _fetchScenes();
      case TodayFilter.quotes:
        _fetchQuotes();
      case TodayFilter.scenes:
        _fetchScenes();
      case TodayFilter.facts:
        _fetchFacts();
    }
  }

  Future<void> _loadFavoriteIds() async {
    final quoteIds = await DriftQuoteService.getAllFavoriteQuoteIds();
    final factIds = await DriftFactService.getAllFavoriteFactIds();
    await DriftSceneService.ensureSeeded();
    final sceneIds = await DriftSceneService.getFavoriteIds();
    talker?.info(
      'Favorites: ${quoteIds.length} quotes, ${factIds.length} '
      'facts, ${sceneIds.length} scenes',
    );
    if (!mounted) return;
    ref.read(favoriteQuoteIdsProvider.notifier).addOrUpdateIdList(quoteIds);
    ref.read(favoriteFactIdsProvider.notifier).addOrUpdateIdList(factIds);
    ref.read(favoriteSceneIdsProvider.notifier).setAll(sceneIds);
  }

  /// First load waits for saved interests so page one is already filtered.
  Future<void> _loadInitialQuotes() async {
    await ref.read(userInterestsProvider.notifier).ready;
    if (!mounted) return;
    _appliedInterests = List.of(ref.read(userInterestsProvider));
    await _fetchQuotes();
    if (!mounted) return;
    setState(() => _initialLoadDone = true);
  }

  Future<void> _refresh() async {
    setState(() {
      quotePageNumber = 1;
      quotes = [];
      hasMoreData = true;
      hasError = false;
      isLoadingMore = false;
      _scenes.clear();
      _scenePage = 1;
      _scenesHasMore = true;
      _facts.clear();
      _factPage = 1;
      _factsHasMore = true;
    });
    ref.invalidate(fetchAllQuotesProvider);
    ref.invalidate(sceneQuotesPageProvider);
    ref.invalidate(fetchAllFactsProvider);
    ref.invalidate(fetchTodayQuoteOfTheDayProvider);
    ref.invalidate(sceneOfTheDayProvider);
    await Future.wait([
      _fetchQuotes(),
      _fetchScenes(),
      if (_filter == TodayFilter.facts) _fetchFacts(),
    ]);
  }

  Future<void> _fetchQuotes() async {
    if (!hasMoreData || isLoadingMore) return;
    if (quotePageNumber > 1) {
      analytics.logEvent(
        name: 'quotes_paginated',
        parameters: {'page_number': quotePageNumber},
      );
    }
    setState(() {
      isLoadingMore = true;
      hasError = false;
    });
    try {
      final interests = ref.read(userInterestsProvider);
      final effectiveTags = allSelectedTags.isNotEmpty
          ? allSelectedTags
          : (_ignoreInterestsForQuotes ? const <String>[] : interests);
      var page = await ref.read(
        fetchAllQuotesProvider(
          quotePageNumber,
          quotePageSize,
          effectiveTags,
          PaginationSeed.current,
        ).future,
      );
      // Interests can be fact categories that match no quote tag; don't
      // leave the feed empty when quotes exist.
      if (page.quotes.isEmpty &&
          quotePageNumber == 1 &&
          allSelectedTags.isEmpty &&
          effectiveTags.isNotEmpty) {
        _ignoreInterestsForQuotes = true;
        page = await ref.read(
          fetchAllQuotesProvider(
            quotePageNumber,
            quotePageSize,
            const <String>[],
            PaginationSeed.current,
          ).future,
        );
      }
      if (!mounted) return;
      setState(() {
        hasMoreData = page.quotes.length == quotePageSize;
        quotePageNumber++;
        quotes.addAll(
          page.quotes.where((q) => !quotes.any((x) => x.id == q.id)),
        );
        isLoadingMore = false;
      });
    } catch (e) {
      if (kDebugMode) print(e);
      analytics.logEvent(
        name: 'quote_fetch_failed',
        parameters: {'page_number': quotePageNumber, 'error': e.toString()},
      );
      if (mounted) {
        setState(() {
          hasError = true;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _fetchScenes() async {
    if (_scenesLoading || !_scenesHasMore) return;
    setState(() => _scenesLoading = true);
    try {
      await ref.read(screenInterestsProvider.notifier).ready;
      final types = typesToCsv(ref.read(screenInterestsProvider));
      final page = await ref.read(
        sceneQuotesPageProvider(
          pageNumber: _scenePage,
          pageSize: 10,
          typesCsv: types,
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _scenesHasMore = page.length == 10;
        _scenePage++;
        _scenes.addAll(page.where((s) => !_scenes.any((x) => x.id == s.id)));
      });
    } catch (_) {
      _scenesHasMore = false;
    } finally {
      if (mounted) setState(() => _scenesLoading = false);
    }
  }

  Future<void> _fetchFacts() async {
    if (_factsLoading || !_factsHasMore) return;
    setState(() => _factsLoading = true);
    try {
      final interests = ref.read(userInterestsProvider);
      final categories = _ignoreInterestsForFacts
          ? const <String>[]
          : interests;
      var page = await ref.read(
        fetchAllFactsProvider(
          _factPage,
          10,
          categories,
          const [],
          PaginationSeed.current,
        ).future,
      );
      if (page.aiFacts.isEmpty && _factPage == 1 && categories.isNotEmpty) {
        _ignoreInterestsForFacts = true;
        page = await ref.read(
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
        _factsHasMore = page.aiFacts.length == 10;
        _factPage++;
        _facts.addAll(
          page.aiFacts.where((f) => !_facts.any((x) => x.id == f.id)),
        );
      });
    } catch (_) {
      _factsHasMore = false;
    } finally {
      if (mounted) setState(() => _factsLoading = false);
    }
  }

  void _toggleTopic(String tag) {
    analytics.logEvent(
      name: 'quote_filter_changed',
      parameters: {
        'toggled_tag': tag,
        'all_selected_tags': allSelectedTags.join(','),
      },
    );
    setState(() {
      allSelectedTags.contains(tag)
          ? allSelectedTags.remove(tag)
          : allSelectedTags.add(tag);
      quotePageNumber = 1;
      quotes = [];
      hasMoreData = true;
      _ignoreInterestsForQuotes = false;
    });
    ref.invalidate(fetchAllQuotesProvider);
    _fetchQuotes();
  }

  void _setFilter(TodayFilter f) {
    setState(() => _filter = f);
    if (f == TodayFilter.facts && _facts.isEmpty) _fetchFacts();
    if (f == TodayFilter.scenes && _scenes.isEmpty) _fetchScenes();
    analytics.logEvent(
      name: 'today_filter_changed',
      parameters: {'filter': f.name},
    );
  }

  Future<void> _ask(String prompt) async {
    final ask = _Ask(prompt);
    setState(() {
      _asks.insert(0, ask);
      _asking = true;
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    analytics.logEvent(
      name: 'composer_query',
      parameters: {'length': prompt.length},
    );
    // The typing dots show for at least ~600ms so the answer reads as a reply.
    final results = await Future.wait([
      ComposerSearchService.ask(prompt),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
    if (!mounted) return;
    setState(() {
      ask.answers = results.first as List<ThreadMessage>;
      _asking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Refetch from the top when interests change (edited from You). Compare
    // by content: lists compare by identity.
    ref.listen(userInterestsProvider, (previous, next) {
      if (!_initialLoadDone) return;
      if (listEquals(_appliedInterests, next)) return;
      _appliedInterests = List.of(next);
      if (allSelectedTags.isNotEmpty) return;
      setState(() {
        quotePageNumber = 1;
        quotes = [];
        hasMoreData = true;
        _ignoreInterestsForQuotes = false;
      });
      ref.invalidate(fetchAllQuotesProvider);
      _fetchQuotes();
    });
    ref.listen(screenInterestsProvider, (previous, next) {
      if (listEquals(previous, next)) return;
      setState(() {
        _scenes.clear();
        _scenePage = 1;
        _scenesHasMore = true;
      });
      _fetchScenes();
    });

    final layout = ref.watch(appearanceProvider.select((a) => a.layout));
    final today = _todayItems(context);

    return SafeArea(
      bottom: false,
      child: ThreadColumn(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Today',
              subtitle: today.isEmpty
                  ? 'Daily thread'
                  : 'Daily thread · ${today.whereType<_TodayMessage>().length} new',
              actions: [
                CircleIconButton(
                  icon: Icons.search_rounded,
                  semanticLabel: 'Search',
                  onTap: () => context.push(Routes.search),
                ),
                const SizedBox(width: 4),
                const _YouAvatar(),
              ],
            ),
            FilterChips<TodayFilter>(
              options: const [
                ChipOption(TodayFilter.all, 'All'),
                ChipOption(TodayFilter.quotes, 'Quotes'),
                ChipOption(TodayFilter.scenes, 'Scenes'),
                ChipOption(TodayFilter.facts, 'Facts'),
              ],
              isSelected: (f) => f == _filter,
              onSelected: _setFilter,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: IosUpdateBanner()),
                    for (final ask in _asks) ..._askSlivers(ask),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.list(
                        children: [
                          for (var i = 0; i < today.length; i++)
                            Entrance(
                              index: i,
                              child: today[i].build(context, layout),
                            ),
                        ],
                      ),
                    ),
                    if (_filter == TodayFilter.all ||
                        _filter == TodayFilter.quotes) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: TimeDivider('More for you'),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: TopicsRow(
                          selected: allSelectedTags,
                          onToggle: _toggleTopic,
                        ),
                      ),
                    ],
                    ..._feedSlivers(layout),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Composer(onSubmit: _ask, busy: _asking),
            ),
          ],
        ),
      ),
    );
  }

  // --- Composer conversation ----------------------------------------------

  List<Widget> _askSlivers(_Ask ask) {
    final t = context.q;
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList.list(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: t.acc,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    ask.prompt,
                    style: context.qt.chip.copyWith(
                      fontSize: 15,
                      color: t.onAcc,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (ask.answers == null)
              const TypingIndicator()
            else if (ask.answers!.isEmpty)
              const ErrorBubble(
                message:
                    'I couldn’t find one for that yet. Try a topic like courage, love or starting over.',
              )
            else
              for (var i = 0; i < ask.answers!.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Entrance(
                  index: i,
                  child: MessageBubble(message: ask.answers![i]),
                ),
              ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: QTextButton(
                label: 'Clear',
                onPressed: () => setState(() => _asks.remove(ask)),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // --- Today's deliveries ---------------------------------------------------

  List<_TodayEntry> _todayItems(BuildContext context) {
    final now = DateTime.now();
    final weekday = now.weekday;
    String at(int h, int m) => MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: h, minute: m));
    final showQuotes =
        _filter == TodayFilter.all || _filter == TodayFilter.quotes;
    final showScenes =
        _filter == TodayFilter.all || _filter == TodayFilter.scenes;
    final showFacts = _filter == TodayFilter.facts;

    final items = <_TodayEntry>[];

    if (showQuotes) {
      final qotd = ref.watch(fetchTodayQuoteOfTheDayProvider);
      if (qotd.hasValue || qotd.isLoading) {
        items.add(_TodayDivider('${at(8, 0)} · Quote of the day'));
        items.add(
          qotd.hasValue
              ? _TodayMessage(
                  ThreadMessage.fromQuote(qotd.value!.toQuoteDto()),
                  hero: true,
                  eyebrow: 'Quote of the day',
                )
              : const _TodaySkeleton(),
        );
      }
      if (weekday == DateTime.monday) {
        final monday = ref.watch(fetchMotivationMondayProvider).value;
        if (monday != null) {
          items.add(_TodayDivider('${at(9, 0)} · Monday motivation'));
          items.add(
            _TodayMessage(
              ThreadMessage.fromQuote(monday.toQuoteDto()),
              eyebrow: 'Monday motivation',
            ),
          );
        }
      }
      final inspiration = ref.watch(fetchTodayDailyInspirationProvider).value;
      if (inspiration != null) {
        items.add(const _TodayDivider('Daily inspiration'));
        items.add(
          _TodayMessage(
            ThreadMessage.fromQuote(inspiration.toQuoteDto()),
            eyebrow: 'Daily inspiration',
          ),
        );
      }
    }

    if (showScenes) {
      final scene = ref.watch(sceneOfTheDayProvider).value;
      if (scene != null) {
        items.add(_TodayDivider('${at(12, 30)} · Scene'));
        items.add(
          _TodayMessage(
            ThreadMessage.fromScene(scene.sceneQuote),
            eyebrow: 'Scene of the day',
          ),
        );
      }
      if (weekday == DateTime.friday) {
        final lines = ref.watch(fridayNightLinesPageProvider(1, 1)).value;
        final line = (lines == null || lines.isEmpty) ? null : lines.first;
        if (line != null &&
            DateUtils.isSameDay(line.sceneDate.toLocal(), now)) {
          items.add(_TodayDivider('${at(19, 0)} · Friday night lines'));
          items.add(
            _TodayMessage(
              ThreadMessage.fromScene(line.sceneQuote),
              eyebrow: 'Friday night lines',
            ),
          );
        }
      }
    }

    if (showFacts) {
      final fact = ref.watch(fetchTodayFactOfTheDayProvider).value;
      if (fact != null) {
        items.add(_TodayDivider('${at(12, 0)} · Fact of the day'));
        items.add(
          _TodayMessage(
            ThreadMessage.fromFact(fact.toAiFactDto()),
            eyebrow: 'Fact of the day',
          ),
        );
      }
      final brain = ref.watch(fetchTodayDailyBrainFoodProvider).value;
      if (brain != null) {
        items.add(_TodayDivider('${at(18, 0)} · Daily brain food'));
        items.add(
          _TodayMessage(
            ThreadMessage.fromFact(brain.toAiFactDto()),
            eyebrow: 'Daily brain food',
          ),
        );
      }
      if (weekday == DateTime.wednesday) {
        final weird = ref.watch(fetchWeirdFactWednesdayProvider).value;
        if (weird != null) {
          items.add(const _TodayDivider('Weird fact Wednesday'));
          items.add(
            _TodayMessage(
              ThreadMessage.fromFact(weird.toAiFactDto()),
              eyebrow: 'Weird fact Wednesday',
            ),
          );
        }
      }
    }

    if (_filter == TodayFilter.all || _filter == TodayFilter.facts) {
      items.add(
        _TodayPill(
          weekday == DateTime.wednesday
              ? 'Weird fact Wednesday · tap to play'
              : 'True or false? · tap to play',
          () => context.go(Routes.facts),
        ),
      );
    }
    if (_filter == TodayFilter.all && _streak >= 2) {
      items.add(
        _TodayPill(
          '$_streak-day streak — keep it going',
          () => context.push(Routes.you),
        ),
      );
    }
    return items;
  }

  // --- Endless feed ---------------------------------------------------------

  List<Widget> _feedSlivers(ThreadLayout layout) {
    final messages = <ThreadMessage>[];
    bool loading;
    bool hasMore;
    VoidCallback retry;
    switch (_filter) {
      case TodayFilter.all:
        // Quotes with a scene woven in every fourth message.
        var s = 0;
        for (var i = 0; i < quotes.length; i++) {
          messages.add(ThreadMessage.fromQuote(quotes[i]));
          if (i % 4 == 3 && s < _scenes.length) {
            messages.add(ThreadMessage.fromScene(_scenes[s++]));
          }
        }
        loading = isLoadingMore || !_initialLoadDone;
        hasMore = hasMoreData;
        retry = () {
          setState(() {
            hasError = false;
            hasMoreData = true;
          });
          _fetchQuotes();
        };
      case TodayFilter.quotes:
        messages.addAll(quotes.map(ThreadMessage.fromQuote));
        loading = isLoadingMore || !_initialLoadDone;
        hasMore = hasMoreData;
        retry = _fetchQuotes;
      case TodayFilter.scenes:
        messages.addAll(_scenes.map(ThreadMessage.fromScene));
        loading = _scenesLoading;
        hasMore = _scenesHasMore;
        retry = _fetchScenes;
      case TodayFilter.facts:
        messages.addAll(_facts.map(ThreadMessage.fromFact));
        loading = _factsLoading;
        hasMore = _factsHasMore;
        retry = _fetchFacts;
    }

    final failed =
        hasError &&
        messages.isEmpty &&
        (_filter == TodayFilter.all || _filter == TodayFilter.quotes);

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        sliver: SliverList.separated(
          itemCount: messages.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, i) => Entrance(
            key: ValueKey(messages[i].key),
            index: i % 10,
            child: layout == ThreadLayout.cards
                ? QuoteCard(message: messages[i])
                : MessageBubble(message: messages[i]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: failed
            ? ErrorBubble(message: 'Failed to get quotes.', onRetry: retry)
            : messages.isEmpty && loading
            ? const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ThreadSkeleton(count: 3),
              )
            : loading
            ? const LoadMoreIndicator()
            : messages.isEmpty
            ? EmptyState(
                pill: 'Nothing here yet',
                message: 'Try another filter or a different topic.',
                action: SecondaryButton(
                  label: 'Try again',
                  expand: false,
                  onPressed: retry,
                ),
              )
            : !hasMore
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: TimeDivider('You’re all caught up'),
              )
            : const SizedBox(height: 24),
      ),
    ];
  }
}

// --- Today entries -------------------------------------------------------------

sealed class _TodayEntry {
  const _TodayEntry();
  Widget build(BuildContext context, ThreadLayout layout);
}

class _TodayDivider extends _TodayEntry {
  final String text;
  const _TodayDivider(this.text);

  @override
  Widget build(BuildContext context, ThreadLayout layout) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: TimeDivider(text),
  );
}

class _TodayMessage extends _TodayEntry {
  final ThreadMessage message;
  final bool hero;
  final String eyebrow;
  const _TodayMessage(this.message, {this.hero = false, required this.eyebrow});

  @override
  Widget build(BuildContext context, ThreadLayout layout) =>
      layout == ThreadLayout.cards
      ? QuoteCard(message: message, eyebrow: eyebrow)
      : MessageBubble(
          message: message,
          variant: hero ? BubbleVariant.hero : BubbleVariant.regular,
          showReactions: hero,
        );
}

class _TodaySkeleton extends _TodayEntry {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context, ThreadLayout layout) =>
      const BubbleSkeleton(width: 0.95, lines: 2);
}

class _TodayPill extends _TodayEntry {
  final String text;
  final VoidCallback onTap;
  const _TodayPill(this.text, this.onTap);

  @override
  Widget build(BuildContext context, ThreadLayout layout) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: SystemPill(text, onTap: onTap),
  );
}

/// 42px `acc` circle with the nickname's initial (or a person icon) → You.
class _YouAvatar extends ConsumerWidget {
  const _YouAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final nickname = ref.watch(nicknameProvider);
    return Tooltip(
      message: 'You',
      excludeFromSemantics: true,
      child: HitTarget(
        semanticLabel: 'You: settings and streak',
        onTap: () => context.push(Routes.you),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.acc, shape: BoxShape.circle),
          child: nickname == null
              ? Icon(Icons.person_rounded, size: 20, color: t.onAcc)
              : Text(
                  nickname.characters.first.toUpperCase(),
                  style: context.qt.chip.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: t.onAcc,
                  ),
                ),
        ),
      ),
    );
  }
}
