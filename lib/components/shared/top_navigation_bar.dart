import 'package:flutter/material.dart';

/// The shared top bar for all tab screens: a gradient icon badge + gradient
/// title on the left, with optional [trailing] content on the right edge.
class TopNavigationBar extends StatelessWidget {
  final String title;

  /// Per-tab identity icon, shown inside the gradient badge.
  final IconData icon;

  /// Optional action/status widget(s) on the right edge.
  final Widget? trailing;

  /// Optional badge tap (the Home screen hides a debug DB viewer here).
  final VoidCallback? onIconTap;

  const TopNavigationBar({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.06,
      child: Row(
        children: [
          GestureDetector(
            onTap: onIconTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: primary.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 19, color: primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: primary,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
