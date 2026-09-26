import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/shared_preference_keys.dart';
import '../../theme/app_theme.dart';
import 'q_controls.dart';
import 'q_sheet.dart';

const kTermsFile = 'assets/legal/terms.md';
const kPrivacyFile = 'assets/legal/privacy.md';

/// Scrollable markdown (Terms, Privacy) in a sheet, in the Thread type.
Future<void> showLegalSheet(
  BuildContext context, {
  required String title,
  required String file,
}) async {
  final markdown = await rootBundle.loadString(file);
  if (!context.mounted) return;
  await showQSheet(
    context,
    builder: (sheet) {
      final t = sheet.q;
      final qt = sheet.qt;
      return QSheetFrame(
        title: title,
        child: MarkdownBody(
          data: markdown,
          styleSheet: MarkdownStyleSheet(
            p: qt.body.copyWith(color: t.ink, fontWeight: FontWeight.w500),
            h1: qt.sectionTitle,
            h2: qt.rowTitle.copyWith(fontSize: 17),
            h3: qt.rowTitle,
            listBullet: qt.body.copyWith(color: t.ink),
            strong: qt.body.copyWith(color: t.ink, fontWeight: FontWeight.w600),
            a: qt.body.copyWith(color: t.accInk, fontWeight: FontWeight.w600),
            blockSpacing: 12,
          ),
        ),
      );
    },
  );
}

/// First-launch (and policy-update) consent. Same versioning as before:
/// [kCurrentLegalVersion] vs the accepted version, with the one-time
/// migration from the legacy bool key.
Future<void> showLegalConsentIfNeeded(BuildContext context) async {
  final preferences = await SharedPreferences.getInstance();
  var accepted = preferences.getInt(kAcceptedLegalVersionKey) ?? 0;
  if (accepted == 0 &&
      (preferences.getBool(kLegacyAcceptedTermsKey) ?? false)) {
    accepted = 2;
    await preferences.setInt(kAcceptedLegalVersionKey, accepted);
    await preferences.remove(kLegacyAcceptedTermsKey);
  }
  if (accepted >= kCurrentLegalVersion) return;
  if (!context.mounted) return;

  final isUpdate = accepted > 0;
  final t = context.q;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: t.surf,
    barrierColor: t.scrim,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheet) => PopScope(
      canPop: false,
      child: _ConsentSheet(isUpdate: isUpdate, preferences: preferences),
    ),
  );
}

class _ConsentSheet extends StatefulWidget {
  final bool isUpdate;
  final SharedPreferences preferences;

  const _ConsentSheet({required this.isUpdate, required this.preferences});

  @override
  State<_ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends State<_ConsentSheet> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    TextSpan link(String text, String title, String file) => TextSpan(
      text: text,
      style: qt.body.copyWith(
        color: t.accInk,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () => showLegalSheet(context, title: title, file: file),
    );
    return QSheetFrame(
      title: widget.isUpdate
          ? 'Our policies have changed'
          : 'Welcome to Quotely',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isUpdate
                ? 'We’ve updated our policies since you last accepted them. Please review and accept to continue.'
                : 'Before you begin, please review our policies. By continuing, you agree to our terms.',
            style: qt.body,
          ),
          const SizedBox(height: 14),
          Semantics(
            checked: _checked,
            label: 'I have read and agree to the Terms and Privacy Policy',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _checked = !_checked),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: _checked ? t.acc : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: _checked ? t.acc : t.line,
                        width: 2,
                      ),
                    ),
                    child: _checked
                        ? Icon(Icons.check_rounded, size: 16, color: t.onAcc)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: qt.body.copyWith(color: t.ink),
                        children: [
                          const TextSpan(text: 'I have read and agree to the '),
                          link(
                            'Terms & Conditions',
                            'Terms & conditions',
                            kTermsFile,
                          ),
                          const TextSpan(text: ' and '),
                          link(
                            'Privacy Policy',
                            'Privacy policy',
                            kPrivacyFile,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Continue to Quotely',
            onPressed: _checked
                ? () async {
                    await widget.preferences.setInt(
                      kAcceptedLegalVersionKey,
                      kCurrentLegalVersion,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
