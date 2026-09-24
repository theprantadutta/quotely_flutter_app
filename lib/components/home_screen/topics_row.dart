import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dtos/tag_dto.dart';
import '../../riverpods/all_tag_data_provider.dart';
import '../../util/pagination_seed.dart';
import '../thread/thread.dart';

/// Today's "Topics" chips: the old quote tag filter, restyled. Loads more
/// tags as it scrolls sideways; multi-select, narrowing the quote feed.
class TopicsRow extends ConsumerStatefulWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const TopicsRow({super.key, required this.selected, required this.onToggle});

  @override
  ConsumerState<TopicsRow> createState() => _TopicsRowState();
}

class _TopicsRowState extends ConsumerState<TopicsRow> {
  final _scroll = ScrollController();
  final List<TagDto> _tags = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
        _fetch();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final res = await ref.read(
        fetchAllTagsProvider(_page, 12, PaginationSeed.current).future,
      );
      final fresh = res.tags.where((t) => !_tags.any((x) => x.id == t.id));
      if (!mounted) return;
      setState(() {
        if (fresh.isEmpty) {
          _hasMore = false;
        } else {
          _tags.addAll(fresh);
          _page++;
        }
      });
    } catch (_) {
      _hasMore = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tags.isEmpty) return const SizedBox(height: 4);
    // Selected topics stay first so they are always visible.
    final names = [
      ...widget.selected,
      for (final t in _tags)
        if (!widget.selected.contains(t.name)) t.name,
    ];
    return FilterChips<String>(
      controller: _scroll,
      options: [for (final n in names) ChipOption(n, n)],
      isSelected: widget.selected.contains,
      onSelected: widget.onToggle,
    );
  }
}
