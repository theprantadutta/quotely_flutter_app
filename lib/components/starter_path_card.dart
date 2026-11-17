import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../navigation/routes.dart';
import '../services/starter_path.dart';
import 'thread/thread.dart';

/// Copy for each step: the ask, a hint, the action (if the card offers
/// one) and what it says once done.
typedef _StepCopy = ({String title, String hint, String? action, String done});

_StepCopy _copy(StarterStep step) => switch (step) {
  StarterStep.save => (
    title: 'Save a line you love.',
    hint: 'Tap the heart on any line. It waits for you in Saved.',
    action: null,
    done: 'Saved. It’s waiting for you in Saved.',
  ),
  StarterStep.trueFalse => (
    title: 'Try today’s True or False.',
    hint: 'A few quick facts. Guess, then find out.',
    action: 'Play',
    done: 'Played. A new round tomorrow.',
  ),
  StarterStep.scenes => (
    title: 'Find a line from a film you love',
    hint: 'Search a title, or browse today’s scenes.',
    action: 'Open Scenes',
    done: 'Found one. Follow a title for its new lines.',
  ),
};

/// The starter path's card at the top of Today: one step a day for a new
/// install's first three days (see [StarterPath]). Nothing otherwise.
class StarterPathCard extends StatelessWidget {
  /// Replaces [StarterPath.instance] (tests).
  final StarterPath? path;

  /// Replaces going to the step's tab (tests).
  final void Function(StarterStep step)? onAction;

  const StarterPathCard({super.key, this.path, this.onAction});

  @override
  Widget build(BuildContext context) {
    final starter = path ?? StarterPath.instance;
    return ListenableBuilder(
      listenable: starter,
      builder: (context, _) {
        final step = starter.visibleStep;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: step == null
              ? const SizedBox(width: double.infinity)
              : _Card(
                  key: ValueKey(step),
                  step: step,
                  path: starter,
                  onAction: onAction ?? (s) => _go(context, s),
                ),
        );
      },
    );
  }

  static void _go(BuildContext context, StarterStep step) {
    switch (step) {
      case StarterStep.trueFalse:
        context.go(Routes.facts);
      case StarterStep.scenes:
        context.go(Routes.scenes);
      case StarterStep.save:
        break;
    }
  }
}

class _Card extends StatelessWidget {
  final StarterStep step;
  final StarterPath path;
  final void Function(StarterStep step) onAction;

  const _Card({
    super.key,
    required this.step,
    required this.path,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    final copy = _copy(step);
    final done = path.isDone(step);
    final action = copy.action;
    final total = StarterStep.values.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        decoration: BoxDecoration(
          color: t.surf.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'DAY ${step.index + 1} OF $total · GETTING STARTED',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: qt.overline.copyWith(color: t.accInk),
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final s in StarterStep.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: path.isDone(s)
                                  ? t.acc
                                  : t.ink.withValues(alpha: 0.16),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    label: done ? '${copy.title} Done.' : null,
                    child: Row(
                      children: [
                        if (done) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: t.acc,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            copy.title,
                            style: qt.rowTitle.copyWith(
                              color: done ? t.mute : t.ink,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: t.mute,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(done ? copy.done : copy.hint, style: qt.meta),
                  if (!done && action != null) ...[
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: action,
                      expand: false,
                      height: 36,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => onAction(step),
                    ),
                  ],
                ],
              ),
            ),
            CircleIconButton(
              icon: Icons.close_rounded,
              semanticLabel: 'Dismiss',
              size: 30,
              background: Colors.transparent,
              foreground: t.mute,
              onTap: () => path.dismiss(step),
            ),
          ],
        ),
      ),
    );
  }
}
