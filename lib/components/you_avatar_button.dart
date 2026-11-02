import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/routes.dart';
import '../state_providers/profile.dart';
import 'thread/thread.dart';

/// The way to You (settings, appearance, notifications, the widget, the
/// offline library, support) from every tab: a small ink circle with the
/// nickname's initial, or a person icon. It sits at the right end of each
/// tab's header; use this one widget everywhere so the tabs can't drift.
class YouAvatarButton extends ConsumerWidget {
  const YouAvatarButton({super.key});

  /// Read by screen readers; tests find the button by it.
  static const semanticLabel = 'You: settings and streak';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final nickname = ref.watch(nicknameProvider);
    return Tooltip(
      message: 'You',
      excludeFromSemantics: true,
      child: HitTarget(
        semanticLabel: semanticLabel,
        onTap: () => context.push(Routes.you),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.ink, shape: BoxShape.circle),
          child: nickname == null || nickname.isEmpty
              ? Icon(Icons.person_rounded, size: 17, color: t.bg)
              : Text(
                  nickname.characters.first.toUpperCase(),
                  style: context.qt.chip.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.bg,
                  ),
                ),
        ),
      ),
    );
  }
}
