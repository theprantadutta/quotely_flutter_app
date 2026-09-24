import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import 'q_controls.dart';
import 'q_pills.dart';
import 'q_sheet.dart';
import 'thread_message.dart';

const _kReportRecipient = 'prantadutta1997@gmail.com';

Future<void> showReportSheet(BuildContext context, ThreadMessage message) =>
    showQSheet(context, builder: (_) => ReportSheet(message: message));

/// "Report this quote" sheet. Sends the same mailto report as the old
/// dialogs (recipient, subject and body format unchanged), extended with the
/// title, character and episode for scenes.
class ReportSheet extends StatefulWidget {
  final ThreadMessage message;

  const ReportSheet({super.key, required this.message});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _issue = TextEditingController();
  final _correction = TextEditingController();
  final _email = TextEditingController();
  late String _reason = _reasons.first;
  bool _showEmail = false;
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

  @override
  void dispose() {
    _issue.dispose();
    _correction.dispose();
    _email.dispose();
    super.dispose();
  }

  String _na(String s) => s.isNotEmpty ? s : 'N/A';

  ({String subject, String body}) _compose() {
    final issue = _issue.text.trim();
    final correction = _correction.text.trim();
    final email = _email.text.trim();
    final m = widget.message;
    switch (m.kind) {
      case MessageKind.quote:
        final q = m.quote!;
        final id = q.id;
        return (
          subject:
              'Quote Report: ${id.substring(0, id.length > 8 ? 8 : id.length)}... - ${q.author}',
          body:
              '''
--- Quote Report ---
Quote ID: ${q.id}
Reported Quote: "${q.content}"
Reported Author: ${q.author}
Category: ${q.tags.join(', ')}

Reason: $_reason
Issue Details: ${_na(issue)}
Suggested Correction (Quote/Author): ${_na(correction)}

Contact Email (Optional): ${_na(email)}
--- End Report ---
''',
        );
      case MessageKind.fact:
        final f = m.fact!;
        return (
          subject: 'Fact Report: ${f.id}...',
          body:
              '''
--- Fact Report ---
Fact ID: ${f.id}
Reported Fact: "${f.content}"
Category: ${f.aiFactCategory}

Reason: $_reason
Issue Details: ${_na(issue)}
Suggested Correct Fact: ${_na(correction)}

Contact Email (Optional): ${_na(email)}
--- End Report ---
''',
        );
      case MessageKind.scene:
        final s = m.scene!;
        final id = s.id;
        return (
          subject:
              'Scene Report: ${id.substring(0, id.length > 8 ? 8 : id.length)}... - ${s.characterName}, ${s.titleName}',
          body:
              '''
--- Scene Report ---
Scene ID: ${s.id}
Reported Line: "${s.content}"
Character: ${s.characterName}
Title: ${s.titleName} (${s.chipMeta})
Episode: ${_na(s.episodeLabel ?? '')}
Tags: ${s.tags.join(', ')}

Reason: $_reason
Issue Details: ${_na(issue)}
Suggested Correction (Character/Title/Line): ${_na(correction)}

Contact Email (Optional): ${_na(email)}
--- End Report ---
''',
        );
    }
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final report = _compose();
    // Spaces stay %20 (some mail clients show a literal "+").
    final subject = Uri.encodeComponent(report.subject).replaceAll('+', '%20');
    final body = Uri.encodeComponent(report.body).replaceAll('+', '%20');
    final uri = Uri.parse(
      'mailto:$_kReportRecipient?subject=$subject&body=$body',
    );
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (await launchUrl(uri)) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_noun[0].toUpperCase()}${_noun.substring(1)} reported. Thank you.',
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email client. Please send manually to $_kReportRecipient',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'An error occurred. Please ensure you have an email app configured.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      debugPrint('Error launching email: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
              controller: _issue,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: context.qt.chip.copyWith(fontSize: 14),
              decoration: const InputDecoration(hintText: 'Tell us what’s up'),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _correction,
            minLines: 1,
            maxLines: 3,
            style: context.qt.chip.copyWith(fontSize: 14),
            decoration: InputDecoration(hintText: _correctionHint),
          ),
          const SizedBox(height: 4),
          if (_showEmail)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: context.qt.chip.copyWith(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Contact email (optional)',
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
