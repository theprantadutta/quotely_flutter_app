import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/quote_widget_intro.dart';
import '../components/thread/thread.dart';
import '../constants/shared_preference_keys.dart';
import '../navigation/routes.dart';
import '../services/app_analytics.dart';
import '../services/home_widget_store.dart';

/// How many steps onboarding has here: the widget step exists only where the
/// widgets do (Android and iOS).
int onboardingStepCount() => QuoteWidgetIntro.platformSupported ? 4 : 3;

/// Onboarding's last, skippable step: "Put Quotely on your home screen",
/// with a live preview of the chosen widget. "Add widget" runs the same flow
/// as Settings (pin where the launcher allows, the steps sheet otherwise and
/// always on iOS). Adding or skipping here retires the one-time introduction
/// on Today.
class WidgetOnboardingScreen extends StatefulWidget {
  static const kRouteName = Routes.widgetOnboarding;

  /// Replaces [addQuoteWidget] (tests).
  final Future<void> Function(BuildContext context, QuotelyWidgetKind kind)?
  onAdd;

  const WidgetOnboardingScreen({super.key, this.onAdd});

  /// Whether the notifications step should continue here rather than to
  /// Today: the widgets exist, and the introduction hasn't been shown.
  static bool shouldShow(SharedPreferences prefs) =>
      QuoteWidgetIntro.platformSupported &&
      !(prefs.getBool(kQuoteWidgetIntroShownKey) ?? false);

  @override
  State<WidgetOnboardingScreen> createState() => _WidgetOnboardingScreenState();
}

class _WidgetOnboardingScreenState extends State<WidgetOnboardingScreen> {
  var _kind = QuotelyWidgetKind.qotd;
  bool _busy = false;

  Future<void> _finish({required bool add}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kQuoteWidgetIntroShownKey, true);
    logAppEvent('onboarding_widget_answer', {
      'answer': add ? 'add' : 'skip',
      if (add) 'kind': _kind.name,
    });
    if (add && mounted) {
      final onAdd = widget.onAdd;
      onAdd != null
          ? await onAdd(context, _kind)
          : await addQuoteWidget(context, kind: _kind, source: 'onboarding');
    }
    if (!mounted) return;
    context.go(Routes.today);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final steps = onboardingStepCount();
    return PageBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ThreadColumn(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    children: [
                      Text(
                        'Step $steps of $steps',
                        style: context.qt.label.copyWith(
                          color: t.accInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Semantics(
                        header: true,
                        child: Text(
                          'Put Quotely on your home screen',
                          style: context.qt.titleScreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A new line every day, without opening the app.',
                        style: context.qt.meta,
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: QuoteWidgetPreview(
                          key: ValueKey(_kind),
                          kind: _kind,
                        ),
                      ),
                      const SizedBox(height: 20),
                      QuoteWidgetChoices(
                        selected: _kind,
                        onChanged: (k) => setState(() => _kind = k),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        quoteWidgetBlurb(_kind),
                        style: context.qt.body.copyWith(color: t.mute),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Add widget',
                        loading: _busy,
                        onPressed: () => _finish(add: true),
                      ),
                      const SizedBox(height: 4),
                      QTextButton(
                        label: 'Not now',
                        onPressed: _busy ? null : () => _finish(add: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
