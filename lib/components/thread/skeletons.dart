import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Loading skeletons, one per screen shape, sharing one [Shimmer].
///
/// Everything inside a [Shimmer] draws in a flat colour; the shimmer
/// repaints those shapes with a soft band of light that sweeps across the
/// whole group, so a screen loads as one surface rather than each bar
/// pulsing on its own. Reduce motion holds the band still.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final base = t.ink.withValues(alpha: t.isDark ? 0.07 : 0.06);
    final light = t.ink.withValues(alpha: t.isDark ? 0.16 : 0.12);
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // The band travels from off the left edge to off the right.
          final x = context.reduceMotion ? 0.5 : -0.6 + 2.2 * _c.value;
          return ShaderMask(
            // srcIn: the bars' own colour is discarded; only their shape remains,
            // filled with the moving gradient.
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => LinearGradient(
              begin: const Alignment(-1, -0.35),
              end: const Alignment(1, 0.35),
              colors: [base, light, base],
              stops: [
                (x - 0.28).clamp(0.0, 1.0),
                x.clamp(0.0, 1.0),
                (x + 0.28).clamp(0.0, 1.0),
              ],
            ).createShader(rect),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A rounded bar; inside a [Shimmer] it takes the shimmer's colour.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

/// Serif text lines at [lineHeight], the last one short.
class _Lines extends StatelessWidget {
  final int count;
  final double lineHeight;
  final double gap;
  static const widths = [0.96, 0.88, 0.93, 0.8];

  const _Lines({
    required this.count,
    required this.lineHeight,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: gap),
            SkeletonBox(
              width:
                  c.maxWidth *
                  (i == count - 1 ? 0.52 : widths[i % widths.length]),
              height: lineHeight,
              radius: lineHeight / 3,
            ),
          ],
        ],
      ),
    );
  }
}

/// Who said it: small avatar, name and a detail line.
class _Byline extends StatelessWidget {
  const _Byline();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SkeletonCircle(size: 34),
      const SizedBox(width: 12),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 13, radius: 5),
          SizedBox(height: 7),
          SkeletonBox(width: 170, height: 11, radius: 5),
        ],
      ),
    ],
  );
}

/// One full-screen Spotlight entry (Today, For you, Scenes): the overline,
/// three large lines, then who said it. Same padding as [SpotlightEntry].
class SpotlightSkeleton extends StatelessWidget {
  const SpotlightSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(26, 24, 76, 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 130, height: 10, radius: 4),
            SizedBox(height: 24),
            _Lines(count: 3, lineHeight: 36, gap: 12),
            SizedBox(height: 30),
            _Byline(),
          ],
        ),
      ),
    );
  }
}

/// The True or false card while its facts load.
class FactCardSkeleton extends StatelessWidget {
  const FactCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, 8, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 150, height: 10, radius: 4),
            SizedBox(height: 90),
            _Lines(count: 5, lineHeight: 26, gap: 12),
            SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

/// One editorial entry: a few text lines, then a small byline.
class EntrySkeleton extends StatelessWidget {
  final int lines;
  final double width;
  final bool byline;

  const EntrySkeleton({
    super.key,
    this.lines = 2,
    this.width = 0.9,
    this.byline = true,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: width,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Lines(count: lines, lineHeight: 20, gap: 10),
          if (byline) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                SkeletonCircle(size: 24),
                SizedBox(width: 9),
                SkeletonBox(width: 110, height: 11, radius: 5),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A column of entries, as lists load (Saved, Facts browse, Search…).
class EntryListSkeleton extends StatelessWidget {
  final int count;

  const EntryListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: 36),
            EntrySkeleton(
              lines: i.isEven ? 3 : 2,
              width: i.isEven ? 0.94 : 0.78,
            ),
          ],
        ],
      ),
    );
  }
}

/// People: round photo, name and a one-line description, count on the right.
class PersonRowSkeleton extends StatelessWidget {
  const PersonRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SkeletonCircle(size: 46),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14, radius: 5),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.85,
                  child: SkeletonBox(height: 11, radius: 5),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(width: 52, height: 11, radius: 5),
        ],
      ),
    );
  }
}

class PeopleListSkeleton extends StatelessWidget {
  final int count;

  const PeopleListSkeleton({super.key, this.count = 7});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [for (var i = 0; i < count; i++) const PersonRowSkeleton()],
      ),
    );
  }
}

/// A horizontal row of poster cards (Scenes: Browse).
class PosterRowSkeleton extends StatelessWidget {
  final double width;

  const PosterRowSkeleton({super.key, this.width = 96});

  @override
  Widget build(BuildContext context) {
    final height = width * 138 / 96;
    return Shimmer(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: width, height: height, radius: 14),
                  const SizedBox(height: 9),
                  SkeletonBox(width: width * 0.8, height: 12, radius: 5),
                  const SizedBox(height: 6),
                  SkeletonBox(width: width * 0.5, height: 10, radius: 5),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A title or author page: header (poster + title, or a centred portrait
/// + name), a paragraph, then entries.
class DetailSkeleton extends StatelessWidget {
  /// Poster header (a title) rather than a centred portrait (an author).
  final bool poster;

  const DetailSkeleton({super.key, this.poster = true});

  @override
  Widget build(BuildContext context) {
    final header = poster
        ? const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 104, height: 150, radius: 14),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    SkeletonBox(width: 60, height: 10, radius: 4),
                    SizedBox(height: 12),
                    SkeletonBox(width: 180, height: 30, radius: 8),
                    SizedBox(height: 10),
                    SkeletonBox(width: 130, height: 12, radius: 5),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        SkeletonBox(width: 86, height: 36, radius: 18),
                        SizedBox(width: 8),
                        SkeletonBox(width: 86, height: 36, radius: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        : const Column(
            children: [
              SkeletonCircle(size: 104),
              SizedBox(height: 16),
              SkeletonBox(width: 170, height: 30, radius: 8),
              SizedBox(height: 10),
              SkeletonBox(width: 110, height: 12, radius: 5),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonBox(width: 86, height: 36, radius: 18),
                  SizedBox(width: 8),
                  SkeletonBox(width: 86, height: 36, radius: 18),
                ],
              ),
            ],
          );
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 26),
            const _Lines(count: 2, lineHeight: 12, gap: 9),
            const SizedBox(height: 36),
            const EntrySkeleton(lines: 2, width: 0.92),
            const SizedBox(height: 34),
            const EntrySkeleton(lines: 3, width: 0.8),
          ],
        ),
      ),
    );
  }
}
