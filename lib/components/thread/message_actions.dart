import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../navigation/routes.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/drift_collection_service.dart';
import '../../services/drift_fact_service.dart';
import '../../services/drift_quote_service.dart';
import '../../services/drift_scene_service.dart';
import '../../state_providers/favorite_fact_ids.dart';
import '../../state_providers/favorite_quote_ids.dart';
import '../../state_providers/scene_state.dart';
import '../../theme/app_theme.dart';
import 'q_controls.dart';
import 'q_image.dart';
import 'q_sheet.dart';
import 'report_sheet.dart';
import 'thread_message.dart';

void _log(String name, Map<String, Object> params) {
  if (!getIt.isRegistered<FirebaseAnalytics>()) return;
  getIt.get<FirebaseAnalytics>().logEvent(name: name, parameters: params);
}

/// Reactive saved state; only the bubble whose status changes rebuilds.
bool watchIsSaved(WidgetRef ref, ThreadMessage m) => switch (m.kind) {
  MessageKind.quote => ref.watch(
    favoriteQuoteIdsProvider.select((ids) => ids.contains(m.quote!.id)),
  ),
  MessageKind.scene => ref.watch(
    favoriteSceneIdsProvider.select((ids) => ids.contains(m.scene!.id)),
  ),
  MessageKind.fact => ref.watch(
    favoriteFactIdsProvider.select((ids) => ids.contains(m.fact!.id)),
  ),
};

bool readIsSaved(WidgetRef ref, ThreadMessage m) => switch (m.kind) {
  MessageKind.quote => ref.read(favoriteQuoteIdsProvider).contains(m.quote!.id),
  MessageKind.scene => ref.read(favoriteSceneIdsProvider).contains(m.scene!.id),
  MessageKind.fact => ref.read(favoriteFactIdsProvider).contains(m.fact!.id),
};

/// Heart toggle: optimistic provider update, then Drift.
Future<void> toggleSaved(WidgetRef ref, ThreadMessage m) async {
  final next = !readIsSaved(ref, m);
  HapticFeedback.lightImpact();
  switch (m.kind) {
    case MessageKind.quote:
      ref
          .read(favoriteQuoteIdsProvider.notifier)
          .addOrUpdateViaStatus(m.quote!.id, next);
      await DriftQuoteService.changeQuoteUpdateStatus(m.quote!, next);
    case MessageKind.scene:
      ref.read(favoriteSceneIdsProvider.notifier).setStatus(m.scene!.id, next);
      await DriftSceneService.setFavorite(m.scene!, next);
    case MessageKind.fact:
      ref
          .read(favoriteFactIdsProvider.notifier)
          .addOrUpdateViaStatus(m.fact!.id, next);
      await DriftFactService.changeFactFavoriteStatus(m.fact!, next);
  }
  _log('favorite_toggled', {'kind': m.kind.name, 'saved': next.toString()});
}

String shareTextFor(ThreadMessage m) => switch (m.kind) {
  // Quote and fact formats are the ones the app has always shared.
  MessageKind.quote =>
    '"${m.quote!.content}" - ${m.quote!.author}\n\nShared via Quotely\n',
  MessageKind.fact => '"${m.fact!.content}"\n\nShared via Quotely\n',
  MessageKind.scene => m.scene!.shareText,
};

Future<void> shareMessage(ThreadMessage m) async {
  _log('content_shared', {'kind': m.kind.name, 'format': 'text'});
  await SharePlus.instance.share(
    ShareParams(
      text: shareTextFor(m),
      subject: switch (m.kind) {
        MessageKind.quote => 'Amazing quote by ${m.sender}',
        MessageKind.scene => '${m.sender} in ${m.scene!.titleName}',
        MessageKind.fact => 'Amazing fact from Quotely',
      },
      sharePositionOrigin: const Rect.fromLTRB(0, 0, 1, 1),
    ),
  );
}

/// Renders [m] as a branded card offscreen and shares the PNG.
Future<void> shareMessageAsImage(BuildContext context, ThreadMessage m) async {
  final key = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);
  final theme = Theme.of(context);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      top: 0,
      child: Transform.translate(
        // Painted, but well outside the visible viewport.
        offset: const Offset(-5000, 0),
        child: Theme(
          data: theme,
          child: RepaintBoundary(
            key: key,
            child: _ShareCard(message: m),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    _log('content_shared', {'kind': m.kind.name, 'format': 'image'});
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'quotely-${m.kind.name}.png',
          ),
        ],
        text: shareTextFor(m),
        sharePositionOrigin: const Rect.fromLTRB(0, 0, 1, 1),
      ),
    );
  } finally {
    entry.remove();
  }
}

/// Author detail for quotes, title detail for scenes; facts go nowhere.
void openSender(BuildContext context, ThreadMessage m) {
  switch (m.kind) {
    case MessageKind.quote:
      if ((m.authorSlug ?? '').isNotEmpty) {
        context.push(Routes.author(m.authorSlug!));
      }
    case MessageKind.scene:
      context.push(Routes.title(m.scene!.titleId, quoteId: m.scene!.id));
    case MessageKind.fact:
      break;
  }
}

/// Long-press / ⋯ menu for any bubble.
Future<void> showMessageActions(
  BuildContext context,
  WidgetRef ref,
  ThreadMessage m,
) {
  HapticFeedback.selectionClick();
  return showQSheet(
    context,
    builder: (sheet) {
      void run(VoidCallback action) {
        Navigator.of(sheet).pop();
        action();
      }

      final saved = readIsSaved(ref, m);
      return QSheetFrame(
        child: Column(
          children: [
            SheetAction(
              icon: saved
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: saved ? 'Remove from saved' : 'Save',
              onTap: () => run(() => toggleSaved(ref, m)),
            ),
            SheetAction(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onTap: () => run(() {
                Clipboard.setData(ClipboardData(text: shareTextFor(m)));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Copied')));
              }),
            ),
            SheetAction(
              icon: kShareIcon,
              label: 'Share',
              onTap: () => run(() => shareMessage(m)),
            ),
            SheetAction(
              icon: Icons.image_outlined,
              label: 'Share as image',
              onTap: () => run(() => shareMessageAsImage(context, m)),
            ),
            SheetAction(
              icon: Icons.collections_bookmark_outlined,
              label: 'Save to collection',
              onTap: () => run(() => showSaveToCollection(context, m)),
            ),
            if (m.kind == MessageKind.scene)
              SheetAction(
                icon: Icons.movie_outlined,
                label: 'Open ${m.scene!.titleName}',
                onTap: () => run(() => openSender(context, m)),
              ),
            if (m.kind == MessageKind.quote && (m.authorSlug ?? '').isNotEmpty)
              SheetAction(
                icon: Icons.person_outline_rounded,
                label: 'More from ${m.sender}',
                onTap: () => run(() => openSender(context, m)),
              ),
            SheetAction(
              icon: Icons.flag_outlined,
              label: 'Report',
              onTap: () => run(() => showReportSheet(context, m)),
            ),
          ],
        ),
      );
    },
  );
}

/// Makes sure the item exists in its own Drift table, so a collection can
/// render it later even offline.
Future<void> _persistItem(ThreadMessage m) => switch (m.kind) {
  MessageKind.quote => DriftQuoteService.saveNewQuotesToDatabase([m.quote!]),
  MessageKind.scene => DriftSceneService.saveSceneQuotes([m.scene!]),
  MessageKind.fact => DriftFactService.saveNewFactsToDatabase([m.fact!]),
};

Future<void> showSaveToCollection(BuildContext context, ThreadMessage m) {
  return showQSheet(context, builder: (_) => _CollectionPicker(message: m));
}

class _CollectionPicker extends StatefulWidget {
  final ThreadMessage message;

  const _CollectionPicker({required this.message});

  @override
  State<_CollectionPicker> createState() => _CollectionPickerState();
}

class _CollectionPickerState extends State<_CollectionPicker> {
  Set<int> _member = {};
  final _newName = TextEditingController();

  @override
  void initState() {
    super.initState();
    DriftCollectionService.collectionsContaining(
      widget.message.collectionType,
      widget.message.itemId,
    ).then((ids) {
      if (mounted) setState(() => _member = ids);
    });
  }

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  Future<void> _toggle(int id) async {
    final m = widget.message;
    HapticFeedback.selectionClick();
    if (_member.contains(id)) {
      await DriftCollectionService.remove(id, m.collectionType, m.itemId);
      setState(() => _member = {..._member}..remove(id));
    } else {
      await _persistItem(m);
      await DriftCollectionService.add(id, m.collectionType, m.itemId);
      setState(() => _member = {..._member, id});
    }
  }

  Future<void> _create() async {
    final name = _newName.text.trim();
    if (name.isEmpty) return;
    final id = await DriftCollectionService.create(name);
    _newName.clear();
    await _toggle(id);
    _log('collection_created', {'source': 'bubble'});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return QSheetFrame(
      title: 'Save to collection',
      child: StreamBuilder<List<CollectionSummary>>(
        stream: DriftCollectionService.watchCollections(),
        builder: (context, snapshot) {
          final collections = snapshot.data ?? const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (collections.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No collections yet. Name your first one below.',
                    style: context.qt.body,
                  ),
                ),
              for (final c in collections)
                Semantics(
                  checked: _member.contains(c.id),
                  button: true,
                  label: c.name,
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _toggle(c.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: context.qt.rowTitle),
                                Text(
                                  '${c.count} saved',
                                  style: context.qt.label,
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _member.contains(c.id)
                                  ? t.acc
                                  : Colors.transparent,
                              border: Border.all(
                                color: _member.contains(c.id) ? t.acc : t.line,
                                width: 2,
                              ),
                            ),
                            child: _member.contains(c.id)
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: t.onAcc,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newName,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _create(),
                      style: context.qt.chip.copyWith(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'New collection name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.add_rounded,
                    semanticLabel: 'Create collection',
                    background: t.acc,
                    foreground: t.onAcc,
                    onTap: _create,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The card rendered for "Share as image".
class _ShareCard extends StatelessWidget {
  final ThreadMessage message;

  const _ShareCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final m = message;
    return Material(
      color: t.bg,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        color: t.bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.sender, style: context.qt.label),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: t.surf,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: Text(m.text, style: context.qt.quoteHero),
            ),
            if (m.kind == MessageKind.scene) ...[
              const SizedBox(height: 8),
              Text(
                '${m.scene!.titleName} · ${m.scene!.chipMeta}',
                style: context.qt.label,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                const BrandIcon(size: 22, radius: 6),
                const SizedBox(width: 8),
                Text(
                  'Quotely',
                  style: context.qt.rowTitle.copyWith(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
