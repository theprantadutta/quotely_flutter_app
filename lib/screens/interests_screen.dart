import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/shared/something_went_wrong.dart';
import '../constants/responsive.dart';
import '../riverpods/interest_options_provider.dart';
import '../state_providers/user_interests.dart';
import 'notifications_onboarding_screen.dart';

/// Post-onboarding interest picker. The user selects at least
/// [UserInterests.minInterests] topics (no upper limit) that become the base
/// filter for the Home & Facts screens.
///
/// [isEditing] is true when reached from Settings (saving pops back); false
/// during onboarding (saving enters the app).
class InterestsScreen extends ConsumerStatefulWidget {
  static const kRouteName = '/interests';

  final bool isEditing;

  const InterestsScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  /// How many chips to render initially and to add each time the user scrolls
  /// near the bottom. The full vocabulary lives in memory; we reveal it in
  /// batches so a Wrap never has to build hundreds of chips at once.
  static const int _batchSize = 80;

  final _selected = <String>{};
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  bool _initializedFromSaved = false;
  bool _saving = false;

  /// Number of chips currently revealed from the filtered list.
  int _visibleCount = _batchSize;

  /// Size of the current filtered list — cached from build() so the scroll
  /// listener knows whether there's more to reveal.
  int _filteredCount = 0;

  @override
  void initState() {
    super.initState();
    // The router can land here directly on a fresh launch (onboarding done
    // but no interests saved yet). Only Onboarding and Home remove the native
    // splash, so without this the app would stay hidden behind it forever.
    FlutterNativeSplash.remove();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Reveal the next batch as the user nears the bottom of the list.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320 &&
        _visibleCount < _filteredCount) {
      setState(() => _visibleCount += _batchSize);
    }
  }

  /// Reset the reveal window to the top — used when the search query changes so
  /// results start from the first match.
  void _resetReveal() => _visibleCount = _batchSize;

  void _toggle(String option) {
    setState(() {
      if (_selected.contains(option)) {
        _selected.remove(option);
      } else {
        _selected.add(option);
      }
    });
  }

  Future<void> _save() async {
    if (_selected.length < UserInterests.minInterests || _saving) return;
    setState(() => _saving = true);
    await ref.read(userInterestsProvider.notifier).save(_selected.toList());
    if (!mounted) return;
    if (widget.isEditing) {
      context.pop();
    } else {
      // First-run flow: hand off to the notification primer before Home.
      context.go(NotificationsOnboardingScreen.kRouteName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optionsAsync = ref.watch(interestOptionsProvider);

    // Seed the selection from saved interests once (edit mode, or returning
    // users re-running the picker).
    if (!_initializedFromSaved) {
      final saved = ref.read(userInterestsProvider);
      if (saved.isNotEmpty) _selected.addAll(saved);
      _initializedFromSaved = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Your Interests' : 'Pick your interests',
        ),
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose topics you love. We\'ll tailor your quotes and '
                      'facts to them — pick at least ${UserInterests.minInterests}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() {
                        _query = v.trim();
                        _resetReveal();
                      }),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search interests',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: optionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: SomethingWentWrong(
                      title: 'Failed to load interests.',
                      onRetryPressed: () =>
                          ref.invalidate(interestOptionsProvider),
                    ),
                  ),
                  data: (options) {
                    // Both services fall back to local data and return empty
                    // lists when the API is unreachable on a fresh install, so
                    // an empty vocabulary means the fetch failed — offer a
                    // retry instead of a dead end the user can't save from.
                    if (options.isEmpty) {
                      return Center(
                        child: SomethingWentWrong(
                          title: 'Failed to load interests.',
                          onRetryPressed: () =>
                              ref.invalidate(interestOptionsProvider),
                        ),
                      );
                    }
                    final q = _query.toLowerCase();
                    final filtered = q.isEmpty
                        ? options
                        : options
                              .where((o) => o.toLowerCase().contains(q))
                              .toList();
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No matching interests.'),
                      );
                    }
                    // The whole vocabulary is already in memory, but a Wrap
                    // builds every child eagerly and there can be hundreds —
                    // building them all at once janks the main thread. So we
                    // reveal them in batches, growing the window as the user
                    // scrolls (see _onScroll). Natural order is preserved so
                    // tapping a chip toggles it in place instead of jumping.
                    _filteredCount = filtered.length;
                    final visible = _visibleCount.clamp(0, filtered.length);
                    final base = filtered.take(visible).toList();
                    final baseSet = base.toSet();
                    // Keep any selected items that haven't been scrolled into
                    // view yet (e.g. interests seeded from a previous save in
                    // edit mode) visible and removable.
                    final hiddenSelected = filtered
                        .where(
                          (o) => _selected.contains(o) && !baseSet.contains(o),
                        )
                        .toList();
                    final shown = [...base, ...hiddenSelected];
                    final hasMore = visible < filtered.length;
                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final option in shown)
                                _InterestChip(
                                  label: option,
                                  selected: _selected.contains(option),
                                  onTap: () => _toggle(option),
                                ),
                            ],
                          ),
                          if (hasMore)
                            const Padding(
                              padding: EdgeInsets.only(top: 20, bottom: 4),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _BottomBar(
                count: _selected.length,
                saving: _saving,
                onSave: _save,
                isEditing: widget.isEditing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 15, color: primary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int count;
  final bool saving;
  final bool isEditing;
  final VoidCallback onSave;

  const _BottomBar({
    required this.count,
    required this.saving,
    required this.isEditing,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const min = UserInterests.minInterests;
    final hasMin = count >= min;
    final enabled = hasMin && !saving;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          // Count on its own line; below the minimum, a second line nudges the
          // user toward it (there's no upper limit once met).
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (!hasMin)
                  Text(
                    'Pick at least $min',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: enabled ? onSave : null,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEditing ? 'Save' : 'Continue'),
          ),
        ],
      ),
    );
  }
}
