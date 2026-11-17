import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/routes.dart';
import '../services/app_analytics.dart';
import '../services/notification_service.dart';
import '../services/notification_trim.dart';
import 'review_prompt.dart';
import 'thread/thread.dart';

/// Offers [NotificationTrim] once, at a quiet moment: waits [settle], then
/// shows the sheet only while [isCalm] holds and nothing is on top, checking
/// again every [retryEvery] up to [attempts] times. Returns whether it was
/// shown, so Today doesn't follow it with another sheet in the same visit.
/// [service] and [onChoose] replace FCM and the push to Settings (tests).
Future<bool> maybeOfferNotificationTrim(
  BuildContext context, {
  required bool Function() isCalm,
  NotificationService? service,
  void Function(BuildContext context)? onChoose,
  Duration settle = const Duration(seconds: 6),
  Duration retryEvery = const Duration(seconds: 10),
  int attempts = 6,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!NotificationTrim.shouldOffer(prefs)) return false;
    await Future<void>.delayed(settle);
    for (var i = 0; i < attempts; i++) {
      if (!context.mounted) return false;
      if (isCalm() && ReviewPrompt.nothingOnTop(context)) {
        await _offer(
          context,
          prefs,
          service ?? NotificationService(),
          onChoose ?? (c) => c.push(Routes.notifications),
        );
        return true;
      }
      await Future<void>.delayed(retryEvery);
    }
  } catch (e) {
    debugPrint('Notification trim failed: $e');
  }
  return false;
}

Future<void> _offer(
  BuildContext context,
  SharedPreferences prefs,
  NotificationService service,
  void Function(BuildContext context) onChoose,
) async {
  if (!NotificationTrim.shouldOffer(prefs)) return;
  final before = NotificationTrim.enabledCount(prefs);
  // Remembered as soon as it is shown: swiping it away counts too.
  await NotificationTrim.markShown(prefs);
  if (!context.mounted) return;
  final answer =
      await showQSheet<NotificationTrimAnswer>(
        context,
        builder: (_) => NotificationTrimSheet(enabledCount: before),
      ) ??
      NotificationTrimAnswer.dismissed;
  logAppEvent('notif_trim_answer', {
    'answer': answer.wire,
    'enabled_before': before,
  });
  switch (answer) {
    case NotificationTrimAnswer.keepOne:
      await NotificationTrim.keepJustQuoteOfTheDay(prefs, service);
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Done. Just Quote of the day, every morning.'),
          ),
        );
      }
    case NotificationTrimAnswer.choose:
      if (context.mounted) onChoose(context);
    case NotificationTrimAnswer.keepAll:
    case NotificationTrimAnswer.dismissed:
      break;
  }
}

/// "Too many notifications? Keep just Quote of the Day."
/// [Keep just one] [Choose] [Keep all].
class NotificationTrimSheet extends StatelessWidget {
  /// How many kinds are on now, for the line under the title.
  final int enabledCount;

  const NotificationTrimSheet({super.key, required this.enabledCount});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    void answer(NotificationTrimAnswer a) => Navigator.of(context).pop(a);
    return QSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NOTIFICATIONS · $enabledCount KINDS ON',
            textAlign: TextAlign.center,
            style: context.qt.overline,
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              'Too many notifications?',
              textAlign: TextAlign.center,
              style: context.qt.sectionTitle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep just Quote of the Day: one line, every morning at 8:00. '
            'Everything else stays a tap away in the app.',
            textAlign: TextAlign.center,
            style: context.qt.body.copyWith(color: t.mute),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Keep just one',
            onPressed: () => answer(NotificationTrimAnswer.keepOne),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Choose',
            onPressed: () => answer(NotificationTrimAnswer.choose),
          ),
          const SizedBox(height: 4),
          Center(
            child: QTextButton(
              label: 'Keep all',
              onPressed: () => answer(NotificationTrimAnswer.keepAll),
            ),
          ),
        ],
      ),
    );
  }
}
