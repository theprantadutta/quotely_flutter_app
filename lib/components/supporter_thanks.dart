import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'thread/thread.dart';

/// How long the seal takes to breathe in and out once.
const _kBreath = Duration(milliseconds: 3200);

/// The supporter's mark: the app icon in a terracotta ring with a soft glow
/// that slowly breathes. Still when the system asks for reduced motion.
class SupporterSeal extends StatefulWidget {
  final double size;

  const SupporterSeal({super.key, this.size = 112});

  @override
  State<SupporterSeal> createState() => _SupporterSealState();
}

class _SupporterSealState extends State<SupporterSeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: _kBreath,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final size = widget.size;
    return Semantics(
      label: 'Quotely supporter',
      image: true,
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, child) {
          final v = Curves.easeInOut.transform(_breath.value);
          return Transform.scale(
            scale: 1 + 0.025 * v,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: t.acc.withValues(alpha: 0.22 + 0.16 * v),
                    blurRadius: size * (0.32 + 0.12 * v),
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.045),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [t.acc, t.accSoft, t.acc, t.accInk, t.acc],
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(size * 0.03),
            decoration: BoxDecoration(shape: BoxShape.circle, color: t.bg),
            child: ClipOval(
              child: Image.asset(
                'assets/brand/app/avatar-256.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "SUPPORTER · SINCE 28 OCT 2026", or just "SUPPORTER" when the date is
/// unknown.
String supporterEyebrow(DateTime? since) => since == null
    ? 'Quotely supporter'
    : 'Quotely supporter · since ${DateFormat('d MMM y').format(since)}';

/// The page a supporter sees every time they open Support: the seal, a
/// letter from the maker, what their support keeps going, and a quote. It
/// never asks for anything.
class SupporterLetter extends StatelessWidget {
  final DateTime? since;

  const SupporterLetter({super.key, this.since});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    var i = 0;
    Widget step(Widget child) => Entrance(
      index: i++,
      stagger: const Duration(milliseconds: 90),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        step(const Center(child: SupporterSeal())),
        const SizedBox(height: 28),
        step(
          Center(
            child: Text(
              supporterEyebrow(since).toUpperCase(),
              textAlign: TextAlign.center,
              style: qt.overline.copyWith(color: t.acc),
            ),
          ),
        ),
        const SizedBox(height: 14),
        step(
          Center(
            child: Semantics(
              header: true,
              child: Text(
                'Thank you. Truly.',
                textAlign: TextAlign.center,
                style: qt.quoteSpotlight.copyWith(color: t.ink),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        step(
          QCard(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            color: t.surf.withValues(alpha: 0.72),
            radius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A note from Pranta', style: qt.overline),
                const SizedBox(height: 12),
                Text(
                  'Quotely is made by one person, and it stays free, ad-free '
                  'and private for everyone. That only works because of '
                  'people like you.\n\n'
                  "Every quote that reaches someone's screen in the morning, "
                  'every scene and every fact, you helped put it there. I '
                  "don't take that lightly.\n\n"
                  'Whenever you open this page, I hope you remember that you '
                  'made something good possible.',
                  style: qt.quoteBody.copyWith(color: t.ink, height: 1.45),
                ),
                const SizedBox(height: 16),
                Text('With gratitude,', style: qt.body.copyWith(color: t.mute)),
                Text(
                  'Pranta',
                  style: qt.quoteFeature.copyWith(
                    color: t.ink,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        step(Text('What you keep going', style: qt.overline)),
        const SizedBox(height: 10),
        for (final line in const [
          'Free for everyone, always',
          'No ads and no tracking',
          'A new quote every morning',
        ])
          step(_KeptLine(line)),
        const SizedBox(height: 24),
        step(const _GenerosityQuote()),
      ],
    );
  }
}

class _KeptLine extends StatelessWidget {
  final String text;

  const _KeptLine(this.text);

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: t.acc, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.qt.rowTitle.copyWith(color: t.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerosityQuote extends StatelessWidget {
  const _GenerosityQuote();

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      label: 'No act of kindness, no matter how small, is ever wasted. Aesop.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: t.acc, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No act of kindness, no matter how small, is ever wasted.',
              style: context.qt.quoteFeature.copyWith(color: t.ink),
            ),
            const SizedBox(height: 8),
            Text('Aesop', style: context.qt.label.copyWith(color: t.mute)),
          ],
        ),
      ),
    );
  }
}

/// The moment right after a donation (or a restore): a full-screen thank-you
/// over the page backdrop, with a gentle haptic. [restored] is the shorter
/// "welcome back" form for someone who supported before.
Future<void> showThankYouMoment(BuildContext context, {bool restored = false}) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Thank you',
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, _, _) => _ThankYouMoment(restored: restored),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ThankYouMoment extends StatelessWidget {
  final bool restored;

  const _ThankYouMoment({required this.restored});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    var i = 0;
    Widget step(Widget child) => Entrance(
      index: i++,
      stagger: const Duration(milliseconds: 140),
      child: child,
    );

    return PageBackdrop(
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: ThreadColumn(
            // Airy on a phone; scrolls instead of overflowing when the
            // screen is short (landscape, large text).
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(flex: 2),
                          step(const SupporterSeal(size: 96)),
                          const SizedBox(height: 30),
                          step(
                            Text(
                              restored ? 'WELCOME BACK' : 'FROM THE MAKER',
                              style: qt.overline.copyWith(color: t.acc),
                            ),
                          ),
                          const SizedBox(height: 16),
                          step(
                            Semantics(
                              header: true,
                              child: Text(
                                restored
                                    ? 'You are still a Quotely supporter.'
                                    : 'You just made Quotely possible.',
                                style: qt.quoteSpotlight.copyWith(color: t.ink),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          step(
                            Text(
                              restored
                                  ? 'Your support is back on this device. Thank you, '
                                        'then and now.'
                                  : 'Because of you, someone opens Quotely tomorrow '
                                        'and finds the line they needed, free, with no '
                                        'ads and nothing watching them. That is your '
                                        'doing. Thank you, from the bottom of my heart.',
                              style: qt.quoteBody.copyWith(
                                color: t.ink,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          step(
                            Text(
                              'Pranta',
                              style: qt.quoteFeature.copyWith(
                                color: t.mute,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const Spacer(flex: 3),
                          step(
                            PrimaryButton(
                              label: 'Back to Quotely',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
