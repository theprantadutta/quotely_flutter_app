import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../riverpods/application_info_provider.dart';
import '../thread/thread.dart';
import '../../util/version_compare.dart';

/// iOS-only "update available" banner shown at the top of the home screen.
///
/// The Play Store handles Android via in_app_update (see main.dart), but iOS
/// has no equivalent — so the backend exposes the latest App Store version
/// (managed from the admin dashboard) and this banner links users there.
class IosUpdateBanner extends ConsumerStatefulWidget {
  const IosUpdateBanner({super.key});

  @override
  ConsumerState<IosUpdateBanner> createState() => _IosUpdateBannerState();
}

class _IosUpdateBannerState extends ConsumerState<IosUpdateBanner> {
  // Session-only dismissal: reappears on next app launch until updated.
  static bool _dismissed = false;

  String? _installedVersion;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      PackageInfo.fromPlatform().then((info) {
        if (mounted) setState(() => _installedVersion = info.version);
      });
    }
  }

  Future<void> _openAppStore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS || _dismissed || _installedVersion == null) {
      return const SizedBox.shrink();
    }

    final applicationInfo = ref.watch(fetchApplicationInfoProvider).value;
    final latestVersion = applicationInfo?.iosCurrentVersion;
    final appStoreUrl = applicationInfo?.iosAppUpdateUrl;

    if (applicationInfo == null ||
        latestVersion == null ||
        latestVersion.isEmpty ||
        appStoreUrl == null ||
        appStoreUrl.isEmpty ||
        !isNewerVersion(current: _installedVersion!, latest: latestVersion)) {
      return const SizedBox.shrink();
    }

    // A system message in the thread, like every other notice in Thread.
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: SystemPill(
              'Version $latestVersion is on the App Store · Update',
              icon: Icons.system_update_alt_rounded,
              onTap: () => _openAppStore(appStoreUrl),
            ),
          ),
          CircleIconButton(
            icon: Icons.close_rounded,
            semanticLabel: 'Dismiss update notice',
            size: 30,
            background: Colors.transparent,
            foreground: context.q.mute,
            onTap: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}
