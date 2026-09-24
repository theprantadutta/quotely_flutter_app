import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state_providers/scene_state.dart';
import '../../theme/app_theme.dart';
import 'message_actions.dart';
import 'message_bubble.dart';
import 'q_controls.dart';
import 'q_image.dart';
import 'thread_message.dart';

/// Appearance → Default layout = Cards: one full-width `surf` card per item
/// (radius 28, `quoteHero` text), the restyled successor of the old
/// carousel card.
class QuoteCard extends ConsumerWidget {
  final ThreadMessage message;

  /// Small uppercase label above the text ("QUOTE OF THE DAY").
  final String? eyebrow;

  const QuoteCard({super.key, required this.message, this.eyebrow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final m = message;
    final scene = m.scene;
    return Semantics(
      label: '${m.sender}: ${m.text}',
      onLongPressHint: 'More actions',
      child: Pressable(
        pressedScale: 0.985,
        onLongPress: () => showMessageActions(context, ref, m),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            color: t.surf,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: context.qt.caption.copyWith(
                    color: t.accInk,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 11 * 0.04,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (scene != null && scene.isSpoiler)
                SpoilerBubble(
                  hidden: isSpoilerHidden(ref, scene),
                  onReveal: () => ref
                      .read(revealedSpoilersProvider.notifier)
                      .reveal(scene.id),
                  radius: BorderRadius.circular(12),
                  child: Text(m.text, style: context.qt.quoteHero),
                )
              else
                Text(m.text, style: context.qt.quoteHero),
              if (scene != null) ...[
                const SizedBox(height: 14),
                TitleChip(scene: scene),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => openSender(context, m),
                    child: m.kind == MessageKind.fact
                        ? const BrandAvatar(size: 28)
                        : QAvatar(
                            name: m.sender,
                            imageUrl: watchSenderImage(ref, m),
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.kind == MessageKind.fact
                          ? m.fact!.aiFactCategory
                          : '— ${m.sender}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.qt.meta.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              // Own line, so a long name is never squeezed by the pills.
              const SizedBox(height: 12),
              ReactionRow(message: m),
            ],
          ),
        ),
      ),
    );
  }
}
