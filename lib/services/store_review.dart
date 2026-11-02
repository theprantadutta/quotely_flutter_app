import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

/// Numeric Apple App Store ID for Quotely, from App Store Connect.
const String kAppStoreId = '6778280010';

const _androidPackage = 'com.pranta.quotely';

/// "Rate Quotely": opens the store listing on its review page. Used by the
/// Support screen and the You screen.
Future<void> openStoreReviewPage() async {
  try {
    final uri = Platform.isIOS
        ? Uri.parse(
            'https://apps.apple.com/app/id$kAppStoreId?action=write-review',
          )
        : Uri.parse('market://details?id=$_androidPackage');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && !Platform.isIOS) {
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=$_androidPackage',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  } catch (e) {
    debugPrint('Opening the store review page failed: $e');
  }
}

/// Asks the OS for its native review dialog. The OS decides whether it
/// actually shows (quotas on both platforms), so this is fire and forget.
/// Replaceable in tests.
Future<void> Function() requestInAppReview = () async {
  try {
    final review = InAppReview.instance;
    if (await review.isAvailable()) await review.requestReview();
  } catch (e) {
    debugPrint('In-app review request failed: $e');
  }
};
