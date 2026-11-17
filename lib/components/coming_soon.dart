import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../dtos/coming_soon_dto.dart';
import '../navigation/routes.dart';
import '../riverpods/scene_providers.dart';
import '../services/app_analytics.dart';
import '../util/countdown.dart';
import 'thread/thread.dart';

/// Opens a title screen by id or slug.
typedef OpenTitle = void Function(String idOrSlug);

void _pushTitle(BuildContext context, String idOrSlug) =>
    context.push(Routes.title(idOrSlug));

/// A Coming soon item was tapped: with one linked title, open it directly;
/// with several, a sheet lists them.
Future<void> openComingSoon(
  BuildContext context,
  ComingSoonDto item, {
  OpenTitle? openTitle,
}) async {
  final open = openTitle ?? (id) => _pushTitle(context, id);
  logAppEvent('coming_soon_opened', {
    'id': item.id,
    'name': item.name,
    'reason': item.reason.name,
    'titles': item.titles.length,
  });
  if (item.titles.isEmpty) return;
  if (item.titles.length == 1) {
    _openLinked(item, item.titles.single, open);
    return;
  }
  await showQSheet<void>(
    context,
    builder: (sheetContext) => ComingSoonSheet(
      item: item,
      onOpen: (title) {
        Navigator.of(sheetContext).pop();
        _openLinked(item, title, open);
      },
    ),
  );
}

void _openLinked(ComingSoonDto item, ComingSoonTitleDto title, OpenTitle open) {
  logAppEvent('coming_soon_title_opened', {
    'id': item.id,
    'title_id': title.id,
    'title_slug': title.slug,
  });
  open(title.route);
}

/// Scenes' "Coming soon" row: upcoming releases and the titles with lines
/// to catch up on first. Hidden entirely while loading or empty.
class ComingSoonStrip extends ConsumerWidget {
  /// Where a linked title opens; the title screen by default.
  final OpenTitle? openTitle;

  const ComingSoonStrip({super.key, this.openTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(comingSoonProvider).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
          child: Semantics(
            header: true,
            child: Text(
              'Coming soon',
              style: context.qt.sectionTitle.copyWith(fontSize: 18),
            ),
          ),
        ),
        SizedBox(
          // Eyebrow + poster + two name lines, with room for large text.
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ComingSoonCard(
              item: items[i],
              eyebrow: countdownLabel(items[i].releaseDate, now),
              onTap: () =>
                  openComingSoon(context, items[i], openTitle: openTitle),
            ),
          ),
        ),
      ],
    );
  }
}

/// A poster card in the Browse style, with the countdown above the name.
class ComingSoonCard extends StatelessWidget {
  final ComingSoonDto item;
  final String eyebrow;
  final VoidCallback onTap;
  final double width;

  const ComingSoonCard({
    super.key,
    required this.item,
    required this.eyebrow,
    required this.onTap,
    this.width = 96,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      label: '${item.name}, $eyebrow',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QPoster(
                url: item.posterUrl,
                width: width,
                height: width * 138 / 96,
                radius: 14,
              ),
              const SizedBox(height: 7),
              // SoftPill's look, but free to ellipsize in a narrow card.
              Text(
                eyebrow.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.qt.overline.copyWith(
                  fontSize: 10,
                  color: t.accInk,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.qt.label.copyWith(
                  color: t.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Before Avengers: Doomsday": the overview, then the titles to open.
class ComingSoonSheet extends StatelessWidget {
  final ComingSoonDto item;
  final ValueChanged<ComingSoonTitleDto> onOpen;

  const ComingSoonSheet({super.key, required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return QSheetFrame(
      title: 'Before ${item.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.overview.isNotEmpty) ...[
            Text(
              item.overview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.qt.caption.copyWith(color: t.mute),
            ),
            const SizedBox(height: 14),
          ],
          for (final title in item.titles)
            _LinkedTitleRow(title: title, onTap: () => onOpen(title)),
        ],
      ),
    );
  }
}

class _LinkedTitleRow extends StatelessWidget {
  final ComingSoonTitleDto title;
  final VoidCallback onTap;

  const _LinkedTitleRow({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      label: '${title.name}, ${title.meta}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              QPoster(url: title.posterUrl, width: 40, height: 58, radius: 8),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.qt.rowTitle.copyWith(color: t.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(title.meta, style: context.qt.caption),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 18, color: t.mute),
            ],
          ),
        ),
      ),
    );
  }
}
