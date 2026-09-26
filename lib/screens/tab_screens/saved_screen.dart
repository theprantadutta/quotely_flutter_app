import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/thread/thread.dart';
import '../../dtos/ai_fact_dto.dart';
import '../../dtos/quote_dto.dart';
import '../../dtos/scene_quote_dto.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/drift_collection_service.dart';
import '../../services/drift_fact_service.dart';
import '../../services/drift_quote_service.dart';
import '../../services/drift_scene_service.dart';
import '../../state_providers/scene_state.dart';

/// Saved: everything hearted, by kind, plus local collections.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  final _analytics = getIt.get<FirebaseAnalytics>();
  MessageKind _kind = MessageKind.quote;
  bool _userPickedKind = false;
  int? _collection;

  List<QuoteDto>? _quotes;
  List<SceneQuoteDto>? _scenes;
  List<AiFactDto>? _facts;
  List<CollectionSummary> _collections = const [];
  List<ThreadMessage>? _collectionItems;

  final List<StreamSubscription<dynamic>> _subs = [];
  StreamSubscription<List<String>>? _collectionSub;

  @override
  void initState() {
    super.initState();
    _subs.addAll([
      DriftQuoteService.watchAllFavoriteQuotes([]).listen(
        (rows) => setState(
          () => _quotes = QuoteDto.fromQuoteList(rows).reversed.toList(),
        ),
        onError: _logError,
      ),
      DriftSceneService.watchFavorites().listen(
        (rows) => setState(() => _scenes = rows),
        onError: _logError,
      ),
      DriftFactService.watchAllFavoriteFacts([]).listen(
        (rows) => setState(
          () =>
              _facts = rows.map(AiFactDto.fromDrift).toList().reversed.toList(),
        ),
        onError: _logError,
      ),
      DriftCollectionService.watchCollections().listen(
        (rows) => setState(() {
          _collections = rows;
          if (_collection != null && !rows.any((c) => c.id == _collection)) {
            _selectCollection(null);
          }
        }),
      ),
    ]);
  }

  void _logError(Object e) => _analytics.logEvent(
    name: 'favorites_${_kind.name}s_load_failed',
    parameters: {'error': e.toString()},
  );

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _collectionSub?.cancel();
    super.dispose();
  }

  CollectionItemType get _type => switch (_kind) {
    MessageKind.quote => CollectionItemType.quote,
    MessageKind.scene => CollectionItemType.scene,
    MessageKind.fact => CollectionItemType.fact,
  };

  void _selectCollection(int? id) {
    _collectionSub?.cancel();
    setState(() {
      _collection = id;
      _collectionItems = null;
    });
    if (id == null) return;
    _collectionSub = DriftCollectionService.watchItemIds(id, _type).listen((
      ids,
    ) async {
      final items = switch (_kind) {
        MessageKind.quote => (await DriftCollectionService.quotesByIds(
          ids,
        )).map(ThreadMessage.fromQuote).toList(),
        MessageKind.scene => (await DriftSceneService.getByIds(
          ids,
        )).map(ThreadMessage.fromScene).toList(),
        MessageKind.fact => (await DriftCollectionService.factsByIds(
          ids,
        )).map(ThreadMessage.fromFact).toList(),
      };
      if (mounted) setState(() => _collectionItems = items);
    });
  }

  void _setKind(MessageKind kind) {
    setState(() {
      _kind = kind;
      _userPickedKind = true;
    });
    _selectCollection(_collection);
    _analytics.logEvent(
      name: 'favorites_view_changed',
      parameters: {'view_name': '${kind.name}s'},
    );
  }

  Future<void> _newCollection() async {
    final name = await _askName(context, title: 'New collection');
    if (name == null || name.isEmpty) return;
    final id = await DriftCollectionService.create(name);
    _analytics.logEvent(
      name: 'collection_created',
      parameters: {'source': 'saved'},
    );
    _selectCollection(id);
  }

  Future<void> _manageCollection(CollectionSummary c) async {
    HapticFeedback.selectionClick();
    await showQSheet(
      context,
      builder: (sheet) => QSheetFrame(
        title: c.name,
        child: Column(
          children: [
            SheetAction(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onTap: () async {
                Navigator.of(sheet).pop();
                final name = await _askName(
                  context,
                  title: 'Rename',
                  initial: c.name,
                );
                if (name != null && name.isNotEmpty) {
                  await DriftCollectionService.rename(c.id, name);
                }
              },
            ),
            SheetAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete collection',
              destructive: true,
              onTap: () {
                Navigator.of(sheet).pop();
                DriftCollectionService.delete(c.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Opens on the first kind that has something, until the user picks one:
  /// a lone saved scene shouldn't greet them with "Nothing saved yet".
  void _autoPickKind() {
    if (_userPickedKind ||
        _quotes == null ||
        _scenes == null ||
        _facts == null) {
      return;
    }
    final counts = {
      MessageKind.quote: _quotes!.length,
      MessageKind.scene: _scenes!.length,
      MessageKind.fact: _facts!.length,
    };
    if (counts[_kind]! > 0) return;
    for (final k in counts.keys) {
      if (counts[k]! > 0) {
        _kind = k;
        return;
      }
    }
  }

  List<ThreadMessage>? get _items {
    if (_collection != null) return _collectionItems;
    return switch (_kind) {
      MessageKind.quote => _quotes?.map(ThreadMessage.fromQuote).toList(),
      MessageKind.scene => _scenes?.map(ThreadMessage.fromScene).toList(),
      MessageKind.fact => _facts?.map(ThreadMessage.fromFact).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(appearanceProvider.select((a) => a.layout));
    final q = _quotes?.length ?? 0;
    final s = _scenes?.length ?? 0;
    final f = _facts?.length ?? 0;
    final total = q + s + f;
    _autoPickKind();
    final items = _items;

    return SafeArea(
      bottom: false,
      child: ThreadColumn(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ScreenHeader(
                title: 'Saved',
                subtitle: total == 1
                    ? '1 thing worth keeping'
                    : '$total things worth keeping',
                actions: [
                  MiniSegmented<ThreadLayout>(
                    options: const [
                      ChipOption(ThreadLayout.thread, 'List'),
                      ChipOption(ThreadLayout.cards, 'Cards'),
                    ],
                    value: layout,
                    onChanged: (l) =>
                        ref.read(appearanceProvider.notifier).setLayout(l),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SegmentedPill<MessageKind>(
                  options: [
                    ChipOption(MessageKind.quote, 'Quotes $q'),
                    ChipOption(MessageKind.scene, 'Scenes $s'),
                    ChipOption(MessageKind.fact, 'Facts $f'),
                  ],
                  value: _kind,
                  onChanged: _setKind,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final c in _collections) ...[
                      _CollectionCard(
                        name: c.name,
                        count: c.count,
                        selected: c.id == _collection,
                        onTap: () => _selectCollection(
                          c.id == _collection ? null : c.id,
                        ),
                        onLongPress: () => _manageCollection(c),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _NewCollectionCard(onTap: _newCollection),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (items == null)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: ThreadSkeleton(count: 3)),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  pill: _collection != null
                      ? 'This collection is empty'
                      : 'Nothing saved yet',
                  message: _collection != null
                      ? 'Long-press any message and choose “Save to collection”.'
                      : 'Tap the heart on any ${_kind.name} to keep it here.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => Entrance(
                    key: ValueKey(items[i].key),
                    index: i % 8,
                    child: layout == ThreadLayout.cards
                        ? QuoteCard(message: items[i])
                        : _SavedCard(message: items[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _askName(
  BuildContext context, {
  required String title,
  String? initial,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showQSheet<String>(
    context,
    builder: (sheet) => QSheetFrame(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(sheet).pop(v.trim()),
            decoration: const InputDecoration(hintText: 'e.g. Morning boost'),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save',
            onPressed: () => Navigator.of(sheet).pop(controller.text.trim()),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}

class _CollectionCard extends StatelessWidget {
  final String name;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CollectionCard({
    required this.name,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final fg = t.ink;
    return Semantics(
      selected: selected,
      button: true,
      label: '$name, $count saved',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 110, maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? t.ink.withValues(alpha: 0.06) : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? t.ink : t.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.qt.rowTitle.copyWith(fontSize: 14, color: fg),
              ),
              Text(
                '$count saved',
                style: context.qt.label.copyWith(color: t.mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCollectionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewCollectionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      label: 'New collection',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedRRect(color: t.line, radius: 18),
          child: Container(
            width: 84,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            child: Text(
              '+ New',
              style: context.qt.rowTitle.copyWith(fontSize: 14, color: t.mute),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedRRect({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => old.color != color;
}

/// Saved item: text 16/700 + avatar, "Who · Source" and a filled heart.
class _SavedCard extends ConsumerWidget {
  final ThreadMessage message;
  const _SavedCard({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final m = message;
    final saved = watchIsSaved(ref, m);
    final scene = m.scene;
    final text = Text(
      m.text,
      style: context.qt.quoteCompact.copyWith(
        fontSize: 16 * context.qt.quoteScale,
      ),
    );
    return Semantics(
      label: '${m.sender}: ${m.text}',
      onLongPressHint: 'More actions',
      child: Pressable(
        pressedScale: 0.985,
        onTap: () => openSender(context, m),
        onLongPress: () => showMessageActions(context, ref, m),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: scene != null && scene.isSpoiler
                    ? SpoilerBubble(
                        hidden: isSpoilerHidden(ref, scene),
                        onReveal: () => ref
                            .read(revealedSpoilersProvider.notifier)
                            .reveal(scene.id),
                        radius: BorderRadius.circular(10),
                        child: text,
                      )
                    : text,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  m.kind == MessageKind.fact
                      ? const BrandAvatar(size: 24)
                      : QAvatar(
                          name: m.sender,
                          imageUrl: watchSenderImage(ref, m),
                          size: 24,
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.sourceLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.qt.label,
                    ),
                  ),
                  HitTarget(
                    semanticLabel: saved ? 'Remove from saved' : 'Save',
                    onTap: () => toggleSaved(ref, m),
                    child: Icon(
                      saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: saved ? t.accInk : t.mute,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
