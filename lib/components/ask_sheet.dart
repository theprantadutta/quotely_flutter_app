import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:material_ui/material_ui.dart';

import '../service_locator/init_service_locators.dart';
import '../services/composer_search_service.dart';
import 'thread/thread.dart';

/// Where the Ask sheet was opened from; logged with `composer_opened`.
enum AskSource {
  todayRail('today_rail'),
  search('search'),
  scenes('scenes'),
  emptyState('empty_state');

  const AskSource(this.analyticsName);

  /// The `source` parameter value in analytics.
  final String analyticsName;
}

/// Opens the Ask sheet ("Ask for a line"). Every entry point goes through
/// here, so they all get the same sheet and the same `composer_opened`
/// event, tagged with [source]. [prefill] starts the prompt field with
/// that text (e.g. the search query).
///
/// Works offline: the sheet asks [ComposerSearchService], which falls back
/// to the on-device search when the server can't be reached.
Future<void> openAskSheet(
  BuildContext context, {
  required AskSource source,
  String? prefill,
}) {
  getIt.get<FirebaseAnalytics>().logEvent(
    name: 'composer_opened',
    parameters: {'source': source.analyticsName},
  );
  final text = prefill?.trim();
  return showQSheet<void>(
    context,
    builder: (_) =>
        AskSheet(prefill: text == null || text.isEmpty ? null : text),
  );
}

/// "Can't find it? Ask for a line." A quiet accent link for empty and
/// no-result states; opens the Ask sheet with [prefill].
class AskForALinePrompt extends StatelessWidget {
  final String? prefill;
  final AskSource source;
  final String text;

  const AskForALinePrompt({
    super.key,
    this.prefill,
    this.source = AskSource.emptyState,
    this.text = 'Can’t find it? Ask for a line',
  });

  @override
  Widget build(BuildContext context) => SystemPill(
    text,
    icon: Icons.auto_awesome_outlined,
    onTap: () => openAskSheet(context, source: source, prefill: prefill),
  );
}

/// The ask sheet: suggestions, a prompt field, and the answers above it.
/// Open it with [openAskSheet].
class AskSheet extends StatefulWidget {
  /// Starting text for the prompt field.
  final String? prefill;

  const AskSheet({super.key, this.prefill});

  @override
  State<AskSheet> createState() => _AskSheetState();
}

class _AskSheetState extends State<AskSheet> {
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
              const AskAnswerSkeleton()
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
          Composer(
            onSubmit: _ask,
            busy: _busy,
            inset: 0,
            initialText: widget.prefill,
          ),
        ],
      ),
    );
  }
}
