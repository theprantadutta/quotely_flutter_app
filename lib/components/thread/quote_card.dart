import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state_providers/scene_state.dart';
import '../../theme/app_theme.dart';
import 'message_actions.dart';
import 'message_bubble.dart';
import 'q_controls.dart';
import 'q_image.dart';
import 'thread_message.dart';

/// Appearance → Default layout = Cards: one hairline-framed card per item
/// with the line large in the reading font.
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
          padding: const EdgeInsets.fromLTRB(22, 22, 14, 12),
          decoration: BoxDecoration(
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: context.qt.overline.copyWith(color: t.accInk),
                ),
                const SizedBox(height: 14),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => openSender(context, m),
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
                    child: Text(
                      m.kind == MessageKind.fact
                          ? m.fact!.aiFactCategory
                          : m.sender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.qt.label.copyWith(color: t.ink),
                    ),
                  ),
                  ReactionRow(message: m),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
