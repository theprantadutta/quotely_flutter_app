import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../components/thread/thread.dart';
import '../dtos/of_the_day_adapters.dart';
import '../navigation/routes.dart';
import '../riverpods/all_daily_brain_food_provider.dart';
import '../riverpods/all_daily_inspiration_provider.dart';
import '../riverpods/all_fact_of_the_day_provider.dart';
import '../riverpods/all_motivation_monday_provider.dart';
import '../riverpods/all_quote_of_the_day_provider.dart';
import '../riverpods/all_weird_fact_wednesday_provider.dart';
import '../riverpods/scene_providers.dart';

/// Every "of the day" delivery in one place. Replaces the six list screens
/// and the six single screens; notification deep links open this with the
/// matching chip and the newest item highlighted.
class PastMessagesScreen extends ConsumerStatefulWidget {
  final PastKind initialKind;
  final bool highlightLatest;
  final String? highlightId;

  const PastMessagesScreen({
    super.key,
    this.initialKind = PastKind.quoteOfTheDay,
    this.highlightLatest = false,
    this.highlightId,
  });

  @override
  ConsumerState<PastMessagesScreen> createState() => _PastMessagesScreenState();
}

class _PastMessagesScreenState extends ConsumerState<PastMessagesScreen> {
  static const _pageSize = 20;
  final _scroll = ScrollController();
  final _chipScroll = ScrollController();
  late PastKind _kind = widget.initialKind;
  final List<ThreadMessage> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  bool _error = false;
  late bool _highlightLatest = widget.highlightLatest;
  late String? _highlightId = widget.highlightId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 500) _fetch();
    });
    _fetch();
    if (_highlightLatest || _highlightId != null) {
      // The 2px outline fades after a moment.
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          setState(() {
            _highlightLatest = false;
            _highlightId = null;
          });
        }
      });
    }
    // Bring the preselected chip into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chipScroll.hasClients) return;
      final i = PastKind.values.indexOf(_kind);
      _chipScroll.jumpTo(
        (i * 110.0).clamp(0, _chipScroll.position.maxScrollExtent),
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _chipScroll.dispose();
    super.dispose();
  }

  Future<List<ThreadMessage>> _load(PastKind kind, int page) async {
    switch (kind) {
      case PastKind.quoteOfTheDay:
        final r = await ref.read(
          fetchAllQuoteOfTheDayProvider(page, _pageSize).future,
        );
        return [
          for (final d in r.quoteOfTheDayWithQuotes)
            ThreadMessage.fromQuote(d.toQuoteDto(), date: d.quoteDate),
        ];
      case PastKind.inspiration:
        final r = await ref.read(
          fetchAllDailyInspirationProvider(page, _pageSize).future,
        );
        return [
          for (final d in r.quoteOfTheDayWithQuotes)
            ThreadMessage.fromQuote(d.toQuoteDto(), date: d.quoteDate),
        ];
      case PastKind.monday:
        final r = await ref.read(
          fetchAllMotivationMondayProvider(page, _pageSize).future,
        );
        return [
          for (final d in r.motivationMondayWithQuotes)
            ThreadMessage.fromQuote(d.toQuoteDto(), date: d.quoteDate),
        ];
      case PastKind.fridayLines:
        final r = await ref.read(
          fridayNightLinesPageProvider(page, _pageSize).future,
        );
        return [
          for (final d in r)
            ThreadMessage.fromScene(d.sceneQuote, date: d.sceneDate),
        ];
      case PastKind.factOfTheDay:
        final r = await ref.read(
          fetchAllFactOfTheDayProvider(page, _pageSize).future,
        );
        return [
          for (final d in r.factOfTheDayWithFacts)
            ThreadMessage.fromFact(d.toAiFactDto(), date: d.factDate),
        ];
      case PastKind.brainFood:
        final r = await ref.read(
          fetchAllDailyBrainFoodProvider(page, _pageSize).future,
        );
        return [
          for (final d in r.dailyBrainFoodWithFacts)
            ThreadMessage.fromFact(d.toAiFactDto(), date: d.factDate),
        ];
      case PastKind.weirdWednesday:
        final r = await ref.read(
          fetchAllWeirdFactWednesdayProvider(page, _pageSize).future,
        );
        return [
          for (final d in r.weirdFactWednesdayWithFacts)
            ThreadMessage.fromFact(d.toAiFactDto(), date: d.factDate),
        ];
    }
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    final kind = _kind;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final page = await _load(kind, _page);
      if (!mounted || kind != _kind) return;
      setState(() {
        _hasMore = page.length == _pageSize;
        _page++;
        _items.addAll(page.where((m) => !_items.any((x) => x.key == m.key)));
        _items.sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
        );
      });
    } catch (e) {
      if (kDebugMode) print(e);
      if (mounted && kind == _kind) setState(() => _error = true);
    } finally {
      if (mounted && kind == _kind) setState(() => _loading = false);
    }
  }

  void _setKind(PastKind kind) {
    setState(() {
      _kind = kind;
      _items.clear();
      _page = 1;
      _hasMore = true;
      _loading = false;
      _highlightLatest = false;
      _highlightId = null;
    });
    _fetch();
  }

  /// "THIS WEEK", "LAST WEEK", then "AUGUST 2026".
  String _group(DateTime date) {
    final now = DateUtils.dateOnly(DateTime.now());
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final d = DateUtils.dateOnly(date.toLocal());
    if (!d.isBefore(monday)) return 'This week';
    if (!d.isBefore(monday.subtract(const Duration(days: 7)))) {
      return 'Last week';
    }
    return DateFormat('MMMM y').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    String? current;
    for (var i = 0; i < _items.length; i++) {
      final m = _items[i];
      final date = m.date ?? DateTime.now();
      final group = _group(date);
      if (group != current) {
        current = group;
        rows.add(
          Padding(
            padding: EdgeInsets.fromLTRB(4, rows.isEmpty ? 6 : 18, 0, 10),
            child: SectionOverline(group, padding: EdgeInsets.zero),
          ),
        );
      }
      final highlighted =
          (_highlightLatest && i == 0) ||
          (_highlightId != null && m.itemId == _highlightId);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Entrance(
            index: i % 8,
            child: _ArchiveRow(
              message: m,
              date: date,
              highlighted: highlighted,
            ),
          ),
        ),
      );
    }

    return ThreadPage(
      title: 'Past messages',
      subtitle: 'Everything we’ve sent you',
      body: Column(
        children: [
          FilterChips<PastKind>(
            controller: _chipScroll,
            options: [for (final k in PastKind.values) ChipOption(k, k.label)],
            isSelected: (k) => k == _kind,
            onSelected: _setKind,
          ),
          Expanded(
            child: RefreshIndicator.adaptive(
              onRefresh: () async {
                _setKind(_kind);
              },
              child: ListView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  ...rows,
                  if (_error && _items.isEmpty)
                    ErrorBubble(
                      message: 'Failed to load past messages.',
                      onRetry: _fetch,
                    )
                  else if (_loading)
                    _items.isEmpty
                        ? const ThreadSkeleton(count: 3)
                        : const LoadMoreIndicator()
                  else if (_items.isEmpty)
                    const EmptyState(
                      pill: 'Nothing sent yet',
                      message: 'New messages land here as they go out.',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveRow extends ConsumerWidget {
  final ThreadMessage message;
  final DateTime date;
  final bool highlighted;

  const _ArchiveRow({
    required this.message,
    required this.date,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final local = date.toLocal();
    final m = message;
    final by = switch (m.kind) {
      MessageKind.quote => '— ${m.sender}',
      MessageKind.scene => '— ${m.sender}, ${m.scene!.titleName}',
      MessageKind.fact => m.fact!.aiFactCategory,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Text(
                  DateFormat('EEE').format(local).toUpperCase(),
                  style: context.qt.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('d').format(local),
                  style: context.qt.sectionTitle.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            label: '${DateFormat.MMMEd().format(local)}. ${m.text}. $by',
            excludeSemantics: true,
            onLongPressHint: 'More actions',
            child: Pressable(
              pressedScale: 0.985,
              onTap: m.kind == MessageKind.fact
                  ? null
                  : () => openSender(context, m),
              onLongPress: () => showMessageActions(context, ref, m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: highlighted ? t.acc : t.line,
                    width: highlighted ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.text, style: context.qt.quoteCompact),
                    const SizedBox(height: 6),
                    Text(by, style: context.qt.label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
