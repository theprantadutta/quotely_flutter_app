import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/thread/thread.dart';
import '../constants/selectors.dart';
import '../dtos/media_title_dto.dart';
import '../navigation/routes.dart';
import '../riverpods/all_facts_categories_data_provider.dart';
import '../riverpods/all_quote_data_provider.dart';
import '../riverpods/interest_options_provider.dart';
import '../state_providers/scene_state.dart';
import '../state_providers/user_interests.dart';
import '../util/pagination_seed.dart';

/// "What should we talk about?" Quote topics, SCREEN types and fact
/// categories. At least [UserInterests.minInterests] picks in total.
///
/// [isEditing]: reached from You (saving pops back) rather than onboarding
/// (saving continues to the notification primer).
class InterestsScreen extends ConsumerStatefulWidget {
  static const kRouteName = Routes.interests;

  final bool isEditing;

  const InterestsScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  static const _quoteBatch = 24;
  static const _factBatch = 16;

  final _selected = <String>{};
  final _screen = <MediaType>{};
  final _search = TextEditingController();
  String _query = '';
  int _quotesShown = _quoteBatch;
  int _factsShown = _factBatch;
  bool _seeded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // The router can land here directly on a fresh launch; only onboarding
    // and Today remove the native splash otherwise.
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int get _count => _selected.length + _screen.length;

  /// Fact categories are the ones the facts API reports. The baked-in
  /// vocabulary covers a cold offline start: categories are Title Case,
  /// quote tags are lowercase.
  bool _isFactCategory(String option, Set<String> known) =>
      known.contains(option.toLowerCase()) ||
      (known.isEmpty &&
          option.isNotEmpty &&
          option[0] == option[0].toUpperCase() &&
          option[0] != option[0].toLowerCase());

  void _toggle(String option) => setState(() {
    _selected.contains(option)
        ? _selected.remove(option)
        : _selected.add(option);
  });

  void _toggleScreen(MediaType type) => setState(() {
    _screen.contains(type) ? _screen.remove(type) : _screen.add(type);
  });

  Future<void> _autoPick() async {
    if (_saving) return;
    final options = ref.read(interestOptionsProvider).value ?? const <String>[];
    setState(() {
      _selected
        ..clear()
        ..addAll(options.take(UserInterests.autoPickCount));
      _screen
        ..clear()
        ..addAll(const [MediaType.movie, MediaType.tv, MediaType.anime]);
    });
    if (!widget.isEditing) await _save();
  }

  /// Warms Today's first page while the user reads the notification primer.
  /// Must read the list back out of userInterestsProvider: provider families
  /// are keyed by ==, which for a List is identity (see git history).
  void _prefetchFirstQuotePage() {
    final interests = ref.read(userInterestsProvider);
    ref
        .read(
          fetchAllQuotesProvider(
            1,
            kHomeQuotePageSize,
            interests,
            PaginationSeed.current,
          ).future,
        )
        .ignore();
  }

  Future<void> _save() async {
    if (_count < UserInterests.minInterests || _saving) return;
    setState(() => _saving = true);
    await ref.read(screenInterestsProvider.notifier).save(_screen.toList());
    await ref.read(userInterestsProvider.notifier).save(_selected.toList());
    _prefetchFirstQuotePage();
    if (!mounted) return;
    if (widget.isEditing) {
      context.pop();
    } else {
      context.go(Routes.notificationsOnboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final options =
        ref.watch(interestOptionsProvider).value ?? const <String>[];
    final categories = {
      for (final c
          in ref.watch(fetchAllFactsCategoriesProvider).value ??
              const <String>[])
        c.toLowerCase(),
    };

    if (!_seeded) {
      _seeded = true;
      _selected.addAll(ref.read(userInterestsProvider));
      _screen.addAll(ref.read(screenInterestsProvider));
    }

    final q = _query.toLowerCase();
    bool matches(String s) => q.isEmpty || s.toLowerCase().contains(q);
    final quoteTags = <String>[];
    final factCats = <String>[];
    for (final o in options) {
      if (!matches(o)) continue;
      (_isFactCategory(o, categories) ? factCats : quoteTags).add(o);
    }
    // Selected ones always stay visible, even past the reveal window.
    List<String> window(List<String> all, int shown) => [
      ...all.take(shown),
      ...all.skip(shown).where(_selected.contains),
    ];
    final screenTypes = MediaType.values
        .where((m) => matches(m.interestLabel))
        .toList();

    Widget chips(List<String> list) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in list)
          InterestChip(
            label: o[0].toUpperCase() + o.substring(1),
            selected: _selected.contains(o),
            onTap: () => _toggle(o),
          ),
      ],
    );

    Widget more(int total, int shown, VoidCallback onTap) => total > shown
        ? Padding(
            padding: const EdgeInsets.only(top: 8),
            child: QTextButton(
              label: 'Show ${(total - shown).clamp(0, 40)} more',
              color: t.accInk,
              onPressed: onTap,
            ),
          )
        : const SizedBox.shrink();

    return PageBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ThreadColumn(
            child: Column(
              children: [
                if (widget.isEditing) const PushHeader(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      widget.isEditing ? 0 : 24,
                      20,
                      20,
                    ),
                    children: [
                      if (!widget.isEditing)
                        Text(
                          'Step 2 of 3',
                          style: context.qt.label.copyWith(
                            color: t.accInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Semantics(
                        header: true,
                        child: Text(
                          widget.isEditing
                              ? 'Your interests'
                              : 'What should we talk about?',
                          style: context.qt.titleScreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pick at least ${UserInterests.minInterests}. You can change this anytime.',
                        style: context.qt.body.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _search,
                        onChanged: (v) => setState(() {
                          _query = v.trim();
                          _quotesShown = _quoteBatch;
                          _factsShown = _factBatch;
                        }),
                        style: context.qt.chip.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          fillColor: Colors.transparent,
                          hintText: 'Search topics',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: t.mute,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(color: t.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(color: t.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(color: t.ink),
                          ),
                        ),
                      ),
                      if (quoteTags.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const SectionOverline('Quotes'),
                        chips(window(quoteTags, _quotesShown)),
                        more(
                          quoteTags.length,
                          _quotesShown,
                          () => setState(() => _quotesShown += 40),
                        ),
                      ],
                      if (screenTypes.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const SectionOverline('Screen', trailing: NewBadge()),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in screenTypes)
                              InterestChip(
                                label: m.interestLabel,
                                selected: _screen.contains(m),
                                onTap: () => _toggleScreen(m),
                              ),
                          ],
                        ),
                      ],
                      if (factCats.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const SectionOverline('Facts'),
                        chips(window(factCats, _factsShown)),
                        more(
                          factCats.length,
                          _factsShown,
                          () => setState(() => _factsShown += 40),
                        ),
                      ],
                      if (options.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: ThreadSkeleton(count: 1),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            _count < UserInterests.minInterests &&
                                options.isNotEmpty
                            ? QTextButton(
                                label: widget.isEditing
                                    ? 'Choose for me'
                                    : 'Choose for me',
                                color: t.accInk,
                                onPressed: _autoPick,
                              )
                            : Text(
                                '$_count picked',
                                style: context.qt.chip.copyWith(
                                  fontSize: 14,
                                  color: t.mute,
                                ),
                              ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 190),
                        child: PrimaryButton(
                          label: widget.isEditing ? 'Save' : 'Continue',
                          loading: _saving,
                          onPressed: _count >= UserInterests.minInterests
                              ? _save
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
