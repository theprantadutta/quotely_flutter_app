import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/thread/thread.dart';
import '../database/database.dart';
import '../dtos/ai_fact_dto.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/quote_dto.dart';
import '../dtos/scene_quote_dto.dart';
import '../service_locator/init_service_locators.dart';

/// Hidden gallery of every Thread component, in either theme, for quick
/// visual checks against the design screenshots. Long-press "Made by Pranta
/// Dutta" on You (debug builds) to open it.
class DebugComponentsScreen extends ConsumerStatefulWidget {
  const DebugComponentsScreen({super.key});

  @override
  ConsumerState<DebugComponentsScreen> createState() =>
      _DebugComponentsScreenState();
}

class _DebugComponentsScreenState extends ConsumerState<DebugComponentsScreen> {
  Brightness _brightness = Brightness.light;
  bool _toggle = true;
  int _segment = 0;
  bool _chip = true;

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);
    return Theme(
      data: buildQuotelyTheme(_brightness, appearance),
      child: Builder(builder: _gallery),
    );
  }

  Widget _gallery(BuildContext context) {
    final d = DateTime.utc(2026);
    final quote = ThreadMessage.fromQuote(
      QuoteDto(
        id: 'debug-quote',
        author: 'Nelson Mandela',
        content: 'It always seems impossible until it’s done.',
        tags: const ['inspiration'],
        authorSlug: 'nelson-mandela',
        length: 44,
        dateAdded: d,
        dateModified: d,
      ),
    );
    SceneQuoteDto scene({bool spoiler = false}) => SceneQuoteDto(
      id: spoiler ? 'debug-spoiler' : 'debug-scene',
      content: spoiler
          ? 'This line hides a big reveal.'
          : 'Hope is a good thing, maybe the best of things.',
      titleId: 'seed-the-shawshank-redemption',
      titleName: 'The Shawshank Redemption',
      titleType: MediaType.movie,
      titleYear: 1994,
      characterId: 'x',
      characterName: 'Andy Dufresne',
      isSpoiler: spoiler,
      tags: const [],
      dateAdded: d,
      dateModified: d,
    );
    final fact = ThreadMessage.fromFact(
      AiFactDto(
        id: -1,
        content: 'In Ohio, it’s illegal to get a fish drunk.',
        aiFactCategory: 'Weird Laws',
        provider: 'debug',
        dateAdded: d,
        dateModified: d,
      ),
    );
    final title = MediaTitleDto(
      id: 'seed-one-piece',
      slug: 'one-piece',
      name: 'One Piece',
      type: MediaType.anime,
      yearStart: 1999,
      genres: const ['Adventure'],
      quoteCount: 84,
      dateAdded: d,
      dateModified: d,
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: SectionOverline(text),
    );

    return ThreadPage(
      title: 'Components',
      trailing: kDebugMode
          ? CircleIconButton(
              icon: Icons.storage_rounded,
              semanticLabel: 'Database viewer',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DriftDbViewer(getIt.get<AppDatabase>()),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          SegmentedPill<Brightness>(
            options: const [
              ChipOption(Brightness.light, 'Light'),
              ChipOption(Brightness.dark, 'Dark'),
            ],
            value: _brightness,
            onChanged: (b) => setState(() => _brightness = b),
          ),
          label('Skeletons'),
          const SizedBox(height: 460, child: SpotlightSkeleton()),
          const SizedBox(height: 420, child: FactCardSkeleton()),
          const EntryListSkeleton(count: 2),
          const SizedBox(height: 24),
          const PeopleListSkeleton(count: 3),
          const SizedBox(height: 16),
          const SizedBox(height: 206, child: PosterRowSkeleton()),
          const DetailSkeleton(),
          const SizedBox(height: 24),
          const DetailSkeleton(poster: false),
          label('Bubbles'),
          const TimeDivider('8:00 AM · Quote of the day'),
          const SizedBox(height: 8),
          MessageBubble(
            message: quote,
            variant: BubbleVariant.hero,
            showReactions: true,
            trackView: false,
          ),
          const SizedBox(height: 12),
          MessageBubble(
            message: ThreadMessage.fromScene(scene()),
            trackView: false,
          ),
          const SizedBox(height: 12),
          MessageBubble(
            message: ThreadMessage.fromScene(scene(spoiler: true)),
            trackView: false,
          ),
          const SizedBox(height: 12),
          MessageBubble(
            message: fact,
            variant: BubbleVariant.compact,
            trackView: false,
          ),
          const SizedBox(height: 12),
          const TypingIndicator(),
          label('Cards'),
          QuoteCard(message: quote, eyebrow: 'Quote of the day'),
          label('Pills'),
          const SystemPill('12-day streak — keep it going'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const NewBadge(),
              const SoftPill('Spoiler shield on', icon: Icons.shield_rounded),
              SuggestionChip(label: 'courage', onTap: () {}),
              InterestChip(
                label: 'Anime',
                selected: _chip,
                onTap: () => setState(() => _chip = !_chip),
              ),
              InterestChip(
                label: 'Games',
                selected: !_chip,
                onTap: () => setState(() => _chip = !_chip),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilterChips<int>(
            padding: EdgeInsets.zero,
            options: const [
              ChipOption(0, 'All'),
              ChipOption(1, 'Quotes'),
              ChipOption(2, 'Scenes'),
              ChipOption(3, 'Facts'),
            ],
            isSelected: (v) => v == _segment,
            onSelected: (v) => setState(() => _segment = v),
          ),
          label('Segmented'),
          SegmentedPill<int>(
            options: const [
              ChipOption(0, 'Quotes 24'),
              ChipOption(1, 'Scenes 11'),
              ChipOption(2, 'Facts 9'),
            ],
            value: _segment.clamp(0, 2),
            onChanged: (v) => setState(() => _segment = v),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: MiniSegmented<int>(
              options: const [ChipOption(0, 'Thread'), ChipOption(1, 'Cards')],
              value: _segment.clamp(0, 1),
              onChanged: (v) => setState(() => _segment = v),
            ),
          ),
          const SizedBox(height: 10),
          const SegmentedProgress(total: 10, done: 3),
          const SizedBox(height: 10),
          const QProgressBar(value: 0.62),
          label('Buttons & controls'),
          PrimaryButton(label: 'Get started', onPressed: () {}),
          const SizedBox(height: 10),
          SecondaryButton(label: 'Cancel', onPressed: () {}),
          const SizedBox(height: 10),
          Row(
            children: [
              QToggle(
                value: _toggle,
                onChanged: (v) => setState(() => _toggle = v),
              ),
              const SizedBox(width: 12),
              QToggle(
                value: _toggle,
                large: true,
                onChanged: (v) => setState(() => _toggle = v),
              ),
              const SizedBox(width: 12),
              QRadio(selected: _toggle),
              const SizedBox(width: 12),
              CircleIconButton(
                icon: Icons.search_rounded,
                semanticLabel: 'Search',
                onTap: () {},
              ),
            ],
          ),
          label('Lists'),
          GroupedList(
            children: [
              GroupedRow(
                title: 'Appearance',
                description: 'Theme, accent, text size',
                chevron: true,
                onTap: () {},
              ),
              GroupedRow(
                title: 'Friday night lines',
                description: 'Fridays 7:00 PM',
                isNew: true,
                trailing: QToggle(
                  value: _toggle,
                  onChanged: (v) => setState(() => _toggle = v),
                ),
              ),
            ],
          ),
          label('Media'),
          Row(
            children: [
              PosterCard(title: title, onTap: () {}),
              const SizedBox(width: 14),
              StoryAvatar(name: 'Mandela', isNew: true, onTap: () {}),
              const SizedBox(width: 14),
              StoryAvatar(name: 'Shaw', isNew: false, onTap: () {}),
            ],
          ),
          const SizedBox(height: 14),
          const StreakCard(
            streak: 12,
            summary: '318 quotes, 64 scenes and 90 facts read',
            week: [
              StreakDay.done,
              StreakDay.done,
              StreakDay.done,
              StreakDay.today,
              StreakDay.future,
              StreakDay.future,
              StreakDay.future,
            ],
          ),
          label('States'),
          const BubbleSkeleton(),
          const EmptyState(
            pill: 'Nothing saved yet',
            message: 'Tap the heart on any quote to keep it here.',
          ),
          ErrorBubble(onRetry: () {}),
          label('Sheets'),
          SecondaryButton(
            label: 'Open report sheet',
            onPressed: () => showReportSheet(context, quote),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Open actions',
            onPressed: () => showMessageActions(context, ref, quote),
          ),
        ],
      ),
    );
  }
}
