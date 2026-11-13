import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../services/user_reports.dart';
import 'thread/thread.dart';

/// The thank-you shown the moment a report is queued, online or not.
const kReportThanks = 'Thanks, we’ll take a look';

/// "Send feedback or report a bug". Goes through the offline outbox, so it
/// works without a connection. [title] lets the review prompt ask "What could
/// be better?" instead.
Future<void> showFeedbackSheet(
  BuildContext context, {
  String title = 'Send feedback',
  UserReportKind initialKind = UserReportKind.feedback,
  String? screen,
}) {
  final from = screen ?? currentScreen(context);
  return showQSheet(
    context,
    builder: (_) =>
        FeedbackSheet(title: title, initialKind: initialKind, screen: from),
  );
}

class FeedbackSheet extends StatefulWidget {
  final String title;
  final UserReportKind initialKind;
  final String? screen;

  const FeedbackSheet({
    super.key,
    this.title = 'Send feedback',
    this.initialKind = UserReportKind.feedback,
    this.screen,
  });

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _message = TextEditingController();
  final _email = TextEditingController();
  late UserReportKind _kind = widget.initialKind;
  bool _includeDevice = true;
  bool _emailError = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _canSend => _message.text.trim().isNotEmpty && !_sending;

  Future<void> _send() async {
    if (!isValidOptionalEmail(_email.text)) {
      setState(() => _emailError = true);
      return;
    }
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    try {
      await UserReports.sendFeedback(
        kind: _kind,
        message: _message.text,
        contactEmail: _email.text,
        includeDevice: _includeDevice,
        screen: widget.screen,
      );
    } catch (e) {
      // Only a failed local save lands here; keep the sheet so nothing is lost.
      debugPrint('Queueing feedback failed: $e');
      if (mounted) setState(() => _sending = false);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Couldn’t save that. Please try again.')),
      );
      return;
    }
    navigator.pop();
    messenger?.showSnackBar(const SnackBar(content: Text(kReportThanks)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final bug = _kind == UserReportKind.bug;
    return QSheetFrame(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedPill<UserReportKind>(
            options: const [
              ChipOption(UserReportKind.feedback, 'Feedback'),
              ChipOption(UserReportKind.bug, 'Bug'),
            ],
            value: _kind,
            onChanged: (k) => setState(() => _kind = k),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('feedback-message'),
            controller: _message,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: UserReportLimits.message,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            style: context.qt.chip.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: bug
                  ? 'What went wrong? What were you doing when it happened?'
                  : 'What’s on your mind? Ideas, likes, gripes…',
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('feedback-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            maxLength: UserReportLimits.email,
            onChanged: (_) {
              if (_emailError) setState(() => _emailError = false);
            },
            style: context.qt.chip.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Email (optional)',
              counterText: '',
              helperText: _emailError
                  ? null
                  : 'Only if you’d like a reply. You can leave it empty.',
              errorText: _emailError
                  ? 'That doesn’t look like an email. Fix it or leave it empty.'
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            checked: _includeDevice,
            label: 'Include device info',
            excludeSemantics: true,
            child: InkWell(
              key: const Key('feedback-device'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _includeDevice = !_includeDevice),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Checkbox(
                      value: _includeDevice,
                      activeColor: t.ink,
                      checkColor: t.bg,
                      side: BorderSide(color: t.line, width: 1.5),
                      onChanged: (v) =>
                          setState(() => _includeDevice = v ?? true),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Include device info', style: context.qt.rowTitle),
                          Text(
                            'App version, phone model, OS and language. '
                            'Helps us fix bugs.',
                            style: context.qt.caption.copyWith(color: t.mute),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Send',
                  height: 52,
                  loading: _sending,
                  onPressed: _canSend ? _send : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
