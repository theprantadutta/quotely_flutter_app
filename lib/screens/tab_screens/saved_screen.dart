import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/ask_sheet.dart';
import '../../components/thread/thread.dart';
import '../../components/settings_button.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/drift_collection_service.dart';
import '../../services/saved_feed_service.dart';
import '../../state_providers/scene_state.dart';

/// Saved, as a personal notebook: one calm, chronological feed of every
/// saved quote, scene and fact under "Saved Tuesday" headers, a "Revisit"
/// line from a while ago at the top, chips to narrow it by kind or by
/// collection (collections are optional tags on saved items), and a local
/// search.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  FirebaseAnalytics? get _analytics => getIt.isRegistered<FirebaseAnalytics>()
      ? getIt.get<FirebaseAnalytics>()
      : null;

  SavedFeed? _feed;
  SavedFilter _filter = SavedFilter.all;
  StreamSubscription<SavedFeed>? _sub;

  bool _searching = false;
  String _query = '';
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  bool _loggedRevisit = false;

  @override
  void initState() {
    super.initState();
    _sub = SavedFeedService.watch().listen(
      (feed) => setState(() {
        _feed = feed;
        final id = _filter.collectionId;
        if (id != null && !feed.collections.any((c) => c.id == id)) {
          _filter = SavedFilter.all;
        }
      }),
      onError: (Object e) => _analytics?.logEvent(
        name: 'favorites_load_failed',
        parameters: {'error': e.toString()},
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _setFilter(SavedFilter filter) {
    if (filter == _filter) return;
    setState(() => _filter = filter);
    _analytics?.logEvent(
      name: 'favorites_view_changed',
      parameters: {
        'view_name': filter.collectionId != null
            ? 'collection'
            : filter.kind == null
            ? 'all'
            : '${filter.kind!.name}s',
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _search.clear();
        _query = '';
      }
    });
    if (_searching) {
      _searchFocus.requestFocus();
      _analytics?.logEvent(name: 'saved_search_opened');
    }
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
                // The tag goes; the saved items stay saved.
                DriftCollectionService.delete(c.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;
    final total = feed?.entries.length ?? 0;
    final now = DateTime.now();
    final items = feed == null
        ? null
        : SavedFeedService.apply(feed, _filter, query: _query);
    final revisit =
        feed != null && _filter.isAll && _query.trim().isEmpty && !_searching
        ? SavedFeedService.revisitFor(feed.entries, now)
        : null;
    if (revisit != null && !_loggedRevisit) {
      _loggedRevisit = true;
      _analytics?.logEvent(
        name: 'saved_revisit_shown',
        parameters: {'kind': revisit.message.kind.name},
      );
    }
    final collection = feed?.collections
        .where((c) => c.id == _filter.collectionId)
        .firstOrNull;

    return SafeArea(
      bottom: false,
      child: ThreadColumn(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: ScreenHeader(
                title: 'Saved',
                subtitle: total == 1
                    ? '1 thing worth keeping'
                    : '$total things worth keeping',
                actions: [
                  if (total > 0)
                    CircleIconButton(
                      icon: _searching
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      semanticLabel: _searching
                          ? 'Close search'
                          : 'Search saved',
                      onTap: _toggleSearch,
                    ),
                  const SettingsButton(),
                ],
              ),
            ),
            if (_searching)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(
                    controller: _search,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
            if (total > 0 && feed != null)
              SliverToBoxAdapter(
                child: FilterChips<SavedFilter>(
                  options: [
                    const ChipOption(SavedFilter.all, 'All'),
                    const ChipOption(
                      SavedFilter.kind(MessageKind.quote),
                      'Quotes',
                    ),
                    const ChipOption(
                      SavedFilter.kind(MessageKind.scene),
                      'Scenes',
                    ),
                    const ChipOption(
                      SavedFilter.kind(MessageKind.fact),
                      'Facts',
                    ),
                    // Collections only once there are any: no "+ New" box.
                    for (final c in feed.collections)
                      ChipOption(SavedFilter.collection(c.id), c.name),
                  ],
                  isSelected: (f) => f == _filter,
                  onSelected: _setFilter,
                ),
              ),
            if (collection != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection.count == 1
                              ? '1 saved in ${collection.name}'
                              : '${collection.count} saved in '
                                    '${collection.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.qt.label,
                        ),
                      ),
                      QTextButton(
                        label: 'Edit',
                        onPressed: () => _manageCollection(collection),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            if (revisit != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverToBoxAdapter(
                  child: QuoteCard(
                    key: const ValueKey('saved-revisit'),
                    message: revisit.message,
                    eyebrow: SavedFeedService.revisitLabel(revisit, now),
                  ),
                ),
              ),
            if (items == null)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: ThreadSkeleton(count: 3)),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(child: _empty(total, collection))
            else
              _FeedList(
                groups: SavedFeedService.group(items, now),
                feed: feed!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _empty(int total, CollectionSummary? collection) {
    if (total == 0) {
      return const EmptyState(
        pill: 'Nothing saved yet',
        message: 'Tap the heart on any quote, scene or fact to keep it here.',
        action: AskForALinePrompt(text: 'Or ask for a line to keep'),
      );
    }
    if (_query.trim().isNotEmpty) {
      return EmptyState(
        pill: 'Nothing saved matches “${_query.trim()}”',
        action: AskForALinePrompt(prefill: _query.trim()),
      );
    }
    if (collection != null) {
      return EmptyState(
        pill: 'Nothing in ${collection.name} yet',
        message:
            'Long-press anything you’ve saved and choose “Add to collection”.',
      );
    }
    final kind = _filter.kind?.name ?? 'thing';
    return EmptyState(
      pill: 'No ${kind}s saved yet',
      message: 'Tap the heart on any $kind to keep it here.',
    );
  }
}

/// The feed under its date headers, as one lazily built list.
class _FeedList extends StatelessWidget {
  final List<SavedGroup> groups;
  final SavedFeed feed;

  const _FeedList({required this.groups, required this.feed});

  @override
  Widget build(BuildContext context) {
    final rows = <Object>[
      for (final g in groups) ...[g.label, ...g.entries],
    ];
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final row = rows[i];
          if (row is String) {
            return SectionOverline(
              row,
              key: ValueKey('header:$row'),
              padding: EdgeInsets.only(
                left: 6,
                top: i == 0 ? 0 : 14,
                bottom: 8,
              ),
            );
          }
          final entry = row as SavedEntry;
          return Padding(
            key: ValueKey(entry.key),
            padding: const EdgeInsets.only(bottom: 10),
            child: Entrance(
              index: i % 8,
              child: _SavedCard(entry: entry, tags: feed.tagsOf(entry)),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: c),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: context.qt.chip.copyWith(fontSize: 14),
      decoration: InputDecoration(
        fillColor: Colors.transparent,
        hintText: 'Search your saved',
        prefixIcon: Icon(Icons.search_rounded, size: 18, color: t.mute),
        border: border(t.line),
        enabledBorder: border(t.line),
        focusedBorder: border(t.ink),
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

/// One saved item: the line (16/700), then avatar, "Who · Source", its
/// collection tags, a ⋯ for more (share, add to collection…) and the heart.
class _SavedCard extends ConsumerWidget {
  final SavedEntry entry;
  final List<String> tags;

  const _SavedCard({required this.entry, this.tags = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final m = entry.message;
    final saved = watchIsSaved(ref, m);
    final scene = m.scene;
    final text = Text(
      m.text,
      style: context.qt.quoteCompact.copyWith(
        fontSize: 16 * context.qt.quoteScale,
      ),
    );
    // Read in order: the line, who said it, the tags, then the buttons. The
    // buttons stay their own, so the card can't be one excluded label.
    return Semantics(
      container: true,
      onLongPressHint: 'More actions',
      child: Pressable(
        pressedScale: 0.985,
        onTap: () => openSender(context, m),
        onLongPress: () => showMessageActions(context, ref, m),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
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
                  ExcludeSemantics(
                    child: m.kind == MessageKind.fact
                        ? const BrandAvatar(size: 24)
                        : QAvatar(
                            name: m.sender,
                            imageUrl: watchSenderImage(ref, m),
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.sourceLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.qt.label,
                        ),
                        if (tags.isNotEmpty)
                          Text(
                            tags.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            semanticsLabel: 'In ${tags.join(', ')}',
                            style: context.qt.label.copyWith(color: t.accInk),
                          ),
                      ],
                    ),
                  ),
                  HitTarget(
                    semanticLabel: 'More actions',
                    onTap: () => showMessageActions(context, ref, m),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: t.mute,
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
