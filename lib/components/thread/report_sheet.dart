import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../services/user_reports.dart';
import '../../theme/app_theme.dart';
import '../feedback_sheet.dart' show kReportThanks;
import 'q_controls.dart';
import 'q_pills.dart';
import 'q_sheet.dart';
import 'thread_message.dart';

Future<void> showReportSheet(BuildContext context, ThreadMessage message) {
  final screen = currentScreen(context);
  return showQSheet(
    context,
    builder: (_) => ReportSheet(message: message, screen: screen),
  );
}

/// "Report this quote" sheet. The flag goes to the backend (Report/Submit)
/// through the offline outbox: saved on the device first, sent when online,
/// so the thank-you shows at once with or without a connection.
class ReportSheet extends StatefulWidget {
  final ThreadMessage message;

  /// The route it was opened from, sent as context.
  final String? screen;

  const ReportSheet({super.key, required this.message, this.screen});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _issue = TextEditingController();
  final _correction = TextEditingController();
  final _email = TextEditingController();
  late String _reason = _reasons.first;
  bool _showEmail = false;
  bool _emailError = false;
  bool _sending = false;

  static const _other = 'Something else';

  List<String> get _reasons => switch (widget.message.kind) {
    MessageKind.quote => const [
      'Wrong author',
      'Quote text is incorrect',
      'Offensive or inappropriate',
      'Duplicate',
      _other,
    ],
    MessageKind.scene => const [
      'Wrong character',
      'Wrong title or episode',
      'Line is incorrect',
      'Offensive or inappropriate',
      'Duplicate',
      _other,
    ],
    MessageKind.fact => const [
      'Factually incorrect',
      'Offensive or inappropriate',
      'Duplicate',
      _other,
    ],
  };

  /// Also the backend's content type: quote, scene or fact.
  String get _noun => switch (widget.message.kind) {
    MessageKind.quote => 'quote',
    MessageKind.scene => 'scene',
    MessageKind.fact => 'fact',
  };

  String get _correctionHint => switch (widget.message.kind) {
    MessageKind.quote => 'Correct author or text (optional)',
    MessageKind.scene => 'Correct character, title or line (optional)',
    MessageKind.fact => 'Correct fact (optional)',
  };

  /// The line as the user saw it, with who said it, for the admin's context.
  String get _snapshot {
    final m = widget.message;
    final who = m.kind == MessageKind.scene
        ? '${m.sender}, ${m.scene!.titleName}'
        : m.sender;
    return who.isEmpty ? m.text : '${m.text} — $who';
  }

  @override
  void dispose() {
    _issue.dispose();
    _correction.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!isValidOptionalEmail(_email.text)) {
      setState(() => _emailError = true);
      return;
    }
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    try {
      await UserReports.flagContent(
        contentType: _noun,
        contentId: widget.message.itemId,
        reason: _reason,
        contentSnapshot: _snapshot,
        message: _reason == _other ? _issue.text : null,
        correction: _correction.text,
        contactEmail: _email.text,
        screen: widget.screen,
      );
    } catch (e) {
      // Only a failed local save lands here; keep the sheet so nothing is lost.
      debugPrint('Queueing the report failed: $e');
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
    final m = widget.message;
    return QSheetFrame(
      title: 'Report this $_noun',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“${m.text}”',
                  style: context.qt.chip.copyWith(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  '— ${m.kind == MessageKind.scene ? '${m.sender}, ${m.scene!.titleName}' : m.sender}',
                  style: context.qt.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionOverline('What’s wrong?'),
          for (final r in _reasons)
            QRadioRow(
              label: r,
              selected: r == _reason,
              onTap: () => setState(() => _reason = r),
            ),
          if (_reason == _other) ...[
            const SizedBox(height: 4),
            TextField(
              key: const Key('report-issue'),
              controller: _issue,
              minLines: 2,
              maxLines: 4,
              maxLength: UserReportLimits.message,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textInputAction: TextInputAction.newline,
              style: context.qt.chip.copyWith(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Tell us what’s up',
                counterText: '',
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            key: const Key('report-correction'),
            controller: _correction,
            minLines: 1,
            maxLines: 3,
            maxLength: UserReportLimits.correction,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            style: context.qt.chip.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: _correctionHint,
              counterText: '',
            ),
          ),
          const SizedBox(height: 4),
          if (_showEmail)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextField(
                key: const Key('report-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                maxLength: UserReportLimits.email,
                onChanged: (_) {
                  if (_emailError) setState(() => _emailError = false);
                },
                style: context.qt.chip.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Contact email (optional)',
                  counterText: '',
                  errorText: _emailError
                      ? 'That doesn’t look like an email. Fix it or leave it empty.'
                      : null,
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: QTextButton(
                label: '+ Add contact email',
                onPressed: () => setState(() => _showEmail = true),
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
                  label: 'Send report',
                  height: 52,
                  loading: _sending,
                  onPressed: _send,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
