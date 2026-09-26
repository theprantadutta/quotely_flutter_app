import 'package:flutter/material.dart';

import '../../dtos/media_title_dto.dart';
import '../../theme/app_theme.dart';
import 'q_controls.dart';
import 'q_image.dart';

/// 56 avatar in a 2px ring (`acc` = something new, `line` = seen) + name.
class StoryAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isNew;
  final VoidCallback onTap;

  const StoryAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      label: isNew ? '$name, new quotes' : name,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isNew ? t.acc : t.line, width: 2),
                ),
                child: ClipOval(
                  child: QNetworkImage(
                    url: imageUrl,
                    width: 52,
                    height: 52,
                    initials: initialsOf(name),
                    initialsSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.qt.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isNew ? t.ink : t.mute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 96×138 poster with a type label, title and quote count. Opens the title.
class PosterCard extends StatelessWidget {
  final MediaTitleDto title;
  final VoidCallback onTap;
  final double width;

  const PosterCard({
    super.key,
    required this.title,
    required this.onTap,
    this.width = 96,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final height = width * 138 / 96;
    return Semantics(
      button: true,
      label: '${title.name}, ${title.type.label}, ${title.quoteCount} quotes',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  QPoster(
                    url: title.posterUrl,
                    width: width,
                    height: height,
                    radius: 14,
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: t.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        title.type.label.toUpperCase(),
                        style: context.qt.badge.copyWith(
                          color: t.mute,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                title.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.qt.label.copyWith(
                  color: t.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text('${title.quoteCount} quotes', style: context.qt.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/// One day in the [StreakCard] week.
enum StreakDay { done, today, future, missed }

/// `accSoft` card with the streak, totals and a Monday-first week of dots.
class StreakCard extends StatelessWidget {
  final int streak;
  final String summary;
  final List<StreakDay> week;

  const StreakCard({
    super.key,
    required this.streak,
    required this.summary,
    required this.week,
  });

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final title = streak <= 0 ? 'Start a streak today' : '$streak-day streak';
    return Semantics(
      label: '$title. $summary',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.accSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.qt.titlePush.copyWith(color: t.accInk)),
            const SizedBox(height: 4),
            Text(
              summary,
              style: context.qt.meta.copyWith(
                color: t.accInk,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  Column(
                    children: [
                      _Dot(state: i < week.length ? week[i] : StreakDay.future),
                      const SizedBox(height: 6),
                      Text(
                        _letters[i],
                        style: context.qt.caption.copyWith(
                          color: t.accInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final StreakDay state;

  const _Dot({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    const size = 28.0;
    return switch (state) {
      StreakDay.done => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: t.acc, shape: BoxShape.circle),
      ),
      StreakDay.today => CustomPaint(
        size: const Size.square(size),
        painter: _DashedCircle(color: t.accInk),
      ),
      StreakDay.future || StreakDay.missed => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: t.accInk.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
      ),
    };
  }
}

class _DashedCircle extends CustomPainter {
  final Color color;

  const _DashedCircle({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rect = (Offset.zero & size).deflate(1);
    const dashes = 8;
    const sweep = 2 * 3.14159265 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => old.color != color;
}
