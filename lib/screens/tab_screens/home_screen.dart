import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/home_screen/ios_update_banner.dart';
import '../../components/thread/thread.dart';
import '../../constants/selectors.dart';
import '../../dtos/of_the_day_adapters.dart';
import '../../dtos/quote_dto.dart';
import '../../dtos/scene_quote_dto.dart';
import '../../main.dart';
import '../../navigation/routes.dart';
import '../../notifications/push_notification.dart';
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
import '../../services/library_sync.dart';
import '../../services/drift_fact_service.dart';
import '../../services/drift_quote_service.dart';
import '../../services/drift_scene_service.dart';
import '../../state_providers/favorite_fact_ids.dart';
import '../../state_providers/favorite_quote_ids.dart';
import '../../state_providers/profile.dart';
import '../../state_providers/scene_state.dart';
import '../../state_providers/user_interests.dart';
import '../../util/pagination_seed.dart';
import '../../util/profanity.dart';

enum _Tab { today, forYou }

/// One of today's deliveries, shown full screen.
class _Spot {
  final ThreadMessage message;
  final String eyebrow;
  const _Spot(this.message, this.eyebrow);
}

/// Today, Spotlight style: one line on screen at a time, full screen.
/// "Today" holds the day's deliveries (quote of the day, scene, fact…)
/// and ends on a short wrap-up; "For you" is the endless feed. Swipe up
/// for the next; the rail on the right saves, shares and asks.
class HomeScreen extends ConsumerStatefulWidget {
  static const kRouteName = Routes.today;
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final analytics = getIt.get<FirebaseAnalytics>();
  final _todayPager = PageController();
  final _feedPager = PageController();
  _Tab _tab = _Tab.today;
  int _todayIndex = 0;
  int _feedIndex = 0;

  // --- Quote feed (same paging + interest fallback as the old Home) -------
  int quotePageNumber = 1;
  final int quotePageSize = kHomeQuotePageSize;
  bool hasMoreData = true;
  bool hasError = false;
  bool isLoadingMore = false;
  List<QuoteDto> quotes = [];
  bool _ignoreInterestsForQuotes = false;
  List<String> _appliedInterests = const [];
  bool _initialLoadDone = false;

  // --- Scenes woven into the feed ---------------------------------------------
  final List<SceneQuoteDto> _scenes = [];
  int _scenePage = 1;
  bool _scenesLoading = false;
  bool _scenesHasMore = true;

  int _streak = 0;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _loadInitialQuotes();
    _loadFavoriteIds();
    _fetchScenes();
    ActivityService.instance.summary().then((s) {
      if (mounted) setState(() => _streak = s.streak);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showLegalConsentIfNeeded(context);
      await PushNotifications.asyncQueue.start();
      // Local first: screens read the local database; this keeps it full.
      // At most once a day, respecting Offline library's Wi-Fi only switch.
      await Future<void>.delayed(const Duration(seconds: 4));
      unawaited(LibrarySync.maybeRunDaily());
    });
  }

  @override
  void dispose() {
    _todayPager.dispose();
    _feedPager.dispose();
    super.dispose();
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
    });
    ref.invalidate(fetchAllQuotesProvider);
    ref.invalidate(sceneQuotesPageProvider);
    ref.invalidate(fetchTodayQuoteOfTheDayProvider);
    ref.invalidate(sceneOfTheDayProvider);
    await Future.wait([_fetchQuotes(), _fetchScenes()]);
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
      final effectiveTags = _ignoreInterestsForQuotes
          ? const <String>[]
          : interests;
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
          page.quotes.where(
            (q) => isClean(q.content) && !quotes.any((x) => x.id == q.id),
          ),
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

  void _setTab(_Tab tab) {
    if (tab == _tab) {
      // Re-tapping the current tab goes back to the top (and refreshes
      // the feed when already there).
      final pager = tab == _Tab.today ? _todayPager : _feedPager;
      final index = tab == _Tab.today ? _todayIndex : _feedIndex;
      if (index == 0 && tab == _Tab.forYou) {
        _refresh();
      } else if (pager.hasClients) {
        pager.animateToPage(
          0,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    setState(() => _tab = tab);
    analytics.logEvent(
      name: 'today_tab_changed',
      parameters: {'tab': tab.name},
    );
  }

  void _openAsk() {
    analytics.logEvent(name: 'composer_opened');
    showQSheet<void>(context, builder: (_) => const _AskSheet());
  }

  /// Quotes with a scene woven in every fourth screen.
  List<ThreadMessage> _feed() {
    final messages = <ThreadMessage>[];
    var s = 0;
    for (var i = 0; i < quotes.length; i++) {
      messages.add(ThreadMessage.fromQuote(quotes[i]));
      if (i % 4 == 3 && s < _scenes.length) {
        messages.add(ThreadMessage.fromScene(_scenes[s++]));
      }
    }
    return messages;
  }

  void _onFeedPage(int i, int length) {
    setState(() => _feedIndex = i);
    HapticFeedback.selectionClick();
    if (i >= length - 4) {
      _fetchQuotes();
      _fetchScenes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refetch from the top when interests change (edited from You). Compare
    // by content: lists compare by identity.
    ref.listen(userInterestsProvider, (previous, next) {
      if (!_initialLoadDone) return;
      if (listEquals(_appliedInterests, next)) return;
      _appliedInterests = List.of(next);
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

    final t = context.q;
    final today = _todaySpots();
    final qotdLoading = ref.watch(fetchTodayQuoteOfTheDayProvider).isLoading;
    final feed = _feed();

    // Today: the deliveries, then the wrap-up screen.
    final todayCount = today.length + 1;
    final todayIndex = _todayIndex.clamp(0, todayCount - 1);
    final feedIndex = _feedIndex.clamp(0, feed.isEmpty ? 0 : feed.length);

    final ThreadMessage? current = _tab == _Tab.today
        ? (todayIndex < today.length ? today[todayIndex].message : null)
        : (feedIndex < feed.length ? feed[feedIndex] : null);

    // The shell draws the nav over this screen (see immersiveTabs).
    final navInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        SpotlightBackdrop(
          tint: t.tintFor(DateTime.now()),
          imageUrl: current?.scene?.posterUrl,
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(tab: _tab, onTab: _setTab),
              if (_tab == _Tab.today && todayCount > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 0),
                  child: SegmentedProgress(
                    total: todayCount,
                    done: todayIndex + 1,
                  ),
                ),
              const IosUpdateBanner(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: navInset),
                  child: IndexedStack(
                    index: _tab.index,
                    children: [
                      _buildToday(today, qotdLoading),
                      _buildFeed(feed),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 6,
          bottom: 18 + navInset,
          child: SpotlightRail(message: current, onAsk: _openAsk),
        ),
      ],
    );
  }

  Widget _buildToday(List<_Spot> today, bool loading) {
    if (today.isEmpty && loading) {
      return const SpotlightSkeleton();
    }
    return PageView.builder(
      controller: _todayPager,
      scrollDirection: Axis.vertical,
      itemCount: today.length + 1,
      onPageChanged: (i) {
        HapticFeedback.selectionClick();
        setState(() => _todayIndex = i);
      },
      itemBuilder: (context, i) {
        if (i < today.length) {
          return SpotlightEntry(
            key: ValueKey(today[i].message.key),
            message: today[i].message,
            eyebrow: today[i].eyebrow,
          );
        }
        return _TodayEnd(
          streak: _streak,
          onForYou: () => _setTab(_Tab.forYou),
          onFacts: () => context.go(Routes.facts),
        );
      },
    );
  }

  Widget _buildFeed(List<ThreadMessage> feed) {
    final loading = isLoadingMore || !_initialLoadDone;
    if (feed.isEmpty) {
      if (hasError) {
        return Center(
          child: ErrorBubble(
            message: 'Failed to get quotes.',
            onRetry: () {
              setState(() {
                hasError = false;
                hasMoreData = true;
              });
              _fetchQuotes();
            },
          ),
        );
      }
      if (loading) {
        return const SpotlightSkeleton();
      }
      return EmptyState(
        pill: 'Nothing here yet',
        message: 'Pull in more by changing your interests in You.',
        action: SecondaryButton(
          label: 'Try again',
          expand: false,
          onPressed: _refresh,
        ),
      );
    }
    return PageView.builder(
      controller: _feedPager,
      scrollDirection: Axis.vertical,
      itemCount: feed.length + 1,
      onPageChanged: (i) => _onFeedPage(i, feed.length),
      itemBuilder: (context, i) {
        if (i < feed.length) {
          final m = feed[i];
          return SpotlightEntry(
            key: ValueKey(m.key),
            message: m,
            eyebrow: m.kind == MessageKind.scene ? 'Scene' : null,
          );
        }
        if (loading) {
          return const SpotlightSkeleton();
        }
        if (hasError) {
          return Center(
            child: ErrorBubble(
              message: 'Couldn’t load more.',
              onRetry: _fetchQuotes,
            ),
          );
        }
        return Center(
          child: Text(
            hasMoreData ? '' : 'You’re all caught up',
            style: context.qt.sectionTitle,
          ),
        );
      },
    );
  }

  // --- Today's deliveries ---------------------------------------------------

  List<_Spot> _todaySpots() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final spots = <_Spot>[];

    final qotd = ref.watch(fetchTodayQuoteOfTheDayProvider).value;
    if (qotd != null) {
      spots.add(
        _Spot(ThreadMessage.fromQuote(qotd.toQuoteDto()), 'Quote of the day'),
      );
    }
    if (weekday == DateTime.monday) {
      final monday = ref.watch(fetchMotivationMondayProvider).value;
      if (monday != null) {
        spots.add(
          _Spot(
            ThreadMessage.fromQuote(monday.toQuoteDto()),
            'Monday motivation',
          ),
        );
      }
    }
    final scene = ref.watch(sceneOfTheDayProvider).value;
    if (scene != null) {
      spots.add(
        _Spot(ThreadMessage.fromScene(scene.sceneQuote), 'Scene of the day'),
      );
    }
    final fact = ref.watch(fetchTodayFactOfTheDayProvider).value;
    if (fact != null) {
      spots.add(
        _Spot(ThreadMessage.fromFact(fact.toAiFactDto()), 'Fact of the day'),
      );
    }
    final inspiration = ref.watch(fetchTodayDailyInspirationProvider).value;
    if (inspiration != null) {
      spots.add(
        _Spot(
          ThreadMessage.fromQuote(inspiration.toQuoteDto()),
          'Daily inspiration',
        ),
      );
    }
    final brain = ref.watch(fetchTodayDailyBrainFoodProvider).value;
    if (brain != null) {
      spots.add(
        _Spot(ThreadMessage.fromFact(brain.toAiFactDto()), 'Daily brain food'),
      );
    }
    if (weekday == DateTime.wednesday) {
      final weird = ref.watch(fetchWeirdFactWednesdayProvider).value;
      if (weird != null) {
        spots.add(
          _Spot(
            ThreadMessage.fromFact(weird.toAiFactDto()),
            'Weird fact Wednesday',
          ),
        );
      }
    }
    if (weekday == DateTime.friday) {
      final lines = ref.watch(fridayNightLinesPageProvider(1, 1)).value;
      final line = (lines == null || lines.isEmpty) ? null : lines.first;
      if (line != null && DateUtils.isSameDay(line.sceneDate.toLocal(), now)) {
        spots.add(
          _Spot(ThreadMessage.fromScene(line.sceneQuote), 'Friday night lines'),
        );
      }
    }
    // Duplicates happen when two deliveries pick the same item.
    final seen = <String>{};
    return [
      for (final s in spots)
        if (seen.add(s.message.key) && isClean(s.message.text)) s,
    ];
  }
}

/// Text tabs "Today · For you" on the left, search and You on the right.
class _Header extends StatelessWidget {
  final _Tab tab;
  final ValueChanged<_Tab> onTab;

  const _Header({required this.tab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    Widget item(_Tab value, String label) {
      final selected = value == tab;
      return Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTab(value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: context.qt.titlePush.copyWith(
                fontSize: 28,
                color: selected ? t.ink : t.ink.withValues(alpha: 0.38),
              ),
              child: Text(label),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 10, 4),
      child: Row(
        children: [
          item(_Tab.today, 'Today'),
          const SizedBox(width: 18),
          item(_Tab.forYou, 'For you'),
          const Spacer(),
          CircleIconButton(
            icon: Icons.search_rounded,
            semanticLabel: 'Search',
            onTap: () => context.push(Routes.search),
          ),
          const _YouAvatar(),
        ],
      ),
    );
  }
}

/// The last Today screen: a short wrap-up with where to go next.
class _TodayEnd extends StatelessWidget {
  final int streak;
  final VoidCallback onForYou;
  final VoidCallback onFacts;

  const _TodayEnd({
    required this.streak,
    required this.onForYou,
    required this.onFacts,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    Widget link(String label, VoidCallback onTap) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: t.ink.withValues(alpha: 0.18)),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: qt.rowTitle)),
              Icon(Icons.arrow_forward_rounded, size: 18, color: t.ink),
            ],
          ),
        ),
      ),
    );

    final wednesday = DateTime.now().weekday == DateTime.wednesday;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 24, 76, 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THAT’S TODAY', style: qt.overline.copyWith(color: t.ink)),
          const SizedBox(height: 18),
          Text(
            streak >= 2
                ? '$streak days in a row. See you tomorrow.'
                : 'You’re all caught up. See you tomorrow.',
            style: qt.quoteSpotlight.copyWith(
              fontSize: qt.quoteSpotlight.fontSize! * 0.8,
            ),
          ),
          const SizedBox(height: 36),
          link('Keep reading in For you', onForYou),
          link(
            wednesday ? 'Weird fact Wednesday: play' : 'True or false? Play',
            onFacts,
          ),
        ],
      ),
    );
  }
}

/// The ask sheet: suggestions, a prompt field, and the answers above it.
class _AskSheet extends StatefulWidget {
  const _AskSheet();

  @override
  State<_AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<_AskSheet> {
  String? _prompt;
  List<ThreadMessage>? _answers;
  bool _busy = false;

  Future<void> _ask(String prompt) async {
    setState(() {
      _prompt = prompt;
      _answers = null;
      _busy = true;
    });
    getIt.get<FirebaseAnalytics>().logEvent(
      name: 'composer_query',
      parameters: {'length': prompt.length},
    );
    // The dots show for at least ~600ms so the answer reads as a reply.
    final results = await Future.wait([
      ComposerSearchService.ask(prompt),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
    if (!mounted) return;
    setState(() {
      _answers = results.first as List<ThreadMessage>;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return QSheetFrame(
      title: 'Ask for a line',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_prompt == null)
            Text(
              'Name a feeling, a topic or a kind of story.',
              style: context.qt.body,
            )
          else ...[
            Text(
              _prompt!.toUpperCase(),
              style: context.qt.overline.copyWith(color: t.accInk),
            ),
            const SizedBox(height: 14),
            if (_answers == null)
              const TypingIndicator()
            else if (_answers!.isEmpty)
              Text(
                'I couldn’t find one for that yet. Try a topic like courage, love or starting over.',
                style: context.qt.body,
              )
            else
              for (var i = 0; i < _answers!.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: t.line),
                  ),
                Entrance(
                  index: i,
                  child: MessageBubble(
                    message: _answers![i],
                    variant: BubbleVariant.compact,
                    showReactions: true,
                  ),
                ),
              ],
          ],
          const SizedBox(height: 18),
          Composer(onSubmit: _ask, busy: _busy, inset: 0),
        ],
      ),
    );
  }
}

/// Small ink circle with the nickname's initial (or a person icon) → You.
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
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.ink, shape: BoxShape.circle),
          child: nickname == null
              ? Icon(Icons.person_rounded, size: 17, color: t.bg)
              : Text(
                  nickname.characters.first.toUpperCase(),
                  style: context.qt.chip.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.bg,
                  ),
                ),
        ),
      ),
    );
  }
}
