import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/thread/thread.dart';
import '../navigation/routes.dart';

class AppearanceScreen extends ConsumerWidget {
  static const kRouteName = Routes.appearance;
  const AppearanceScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final reset = await showQSheet<bool>(
      context,
      builder: (sheet) => QSheetFrame(
        title: 'Reset appearance?',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Theme, accent, text size, reading font and layout go back to their defaults.',
              style: sheet.qt.body,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(sheet).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Reset',
                    height: 52,
                    onPressed: () => Navigator.of(sheet).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (reset != true) return;
    await ref.read(appearanceProvider.notifier).reset();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appearance reset to defaults')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appearanceProvider);
    final c = ref.read(appearanceProvider.notifier);
    final t = context.q;
    final brightness = Theme.of(context).brightness;

    Widget section(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SectionOverline(label), child],
      ),
    );

    return ThreadPage(
      title: 'Appearance',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Live preview: restyles instantly with accent, font and size.
          QCard(
            radius: 28,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const QAvatar(name: 'Benjamin Franklin', size: 30),
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: bubbleRadius(22),
                    ),
                    child: Text(
                      'Well done is better than well said.',
                      style: context.qt.quoteBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
          section(
            'Theme',
            SegmentedPill<ThemeMode>(
              options: const [
                ChipOption(ThemeMode.light, 'Light'),
                ChipOption(ThemeMode.dark, 'Dark'),
                ChipOption(ThemeMode.system, 'System'),
              ],
              value: s.themeMode,
              onChanged: c.setThemeMode,
            ),
          ),
          section(
            'Accent',
            QCard(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in QAccent.values)
                    _Swatch(
                      color: QuotelyTokens.swatch(a, brightness),
                      label: a.label,
                      selected: a == s.accent,
                      onTap: () => c.setAccent(a),
                    ),
                ],
              ),
            ),
          ),
          section(
            'Text size',
            QCard(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'A',
                    style: context.qt.chip.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: s.quoteScale,
                      min: AppearanceSettings.minQuoteScale,
                      max: AppearanceSettings.maxQuoteScale,
                      divisions: 9,
                      label: '${(s.quoteScale * 100).round()}%',
                      semanticFormatterCallback: (v) =>
                          'Text size ${(v * 100).round()} percent',
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        c.previewQuoteScale(v);
                      },
                      onChangeEnd: (_) => c.commitQuoteScale(),
                    ),
                  ),
                  Text(
                    'A',
                    style: context.qt.chip.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          section(
            'Reading font',
            SegmentedPill<ReadingFont>(
              options: [
                for (final f in ReadingFont.values) ChipOption(f, f.label),
              ],
              value: s.readingFont,
              onChanged: c.setReadingFont,
              labelStyle: (f, base) => base.copyWith(
                fontFamily: f.family,
                fontWeight: f.weight,
                fontSize: f == ReadingFont.sans ? base.fontSize : 15,
              ),
            ),
          ),
          section(
            'Default layout',
            SegmentedPill<ThreadLayout>(
              options: const [
                ChipOption(ThreadLayout.thread, 'Thread'),
                ChipOption(ThreadLayout.cards, 'Cards'),
              ],
              value: s.layout,
              onChanged: c.setLayout,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: QTextButton(
              label: 'Reset to defaults',
              onPressed: () => _confirmReset(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

/// 36px accent swatch; selected gets a 3px gap + 2px `acc` ring.
class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label accent',
      excludeSemantics: true,
      child: HitTarget(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? t.acc : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
