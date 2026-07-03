import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../riverpods/application_info_provider.dart';
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

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openAppStore(appStoreUrl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.system_update_alt_rounded,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update available',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Version $latestVersion is on the App Store',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _openAppStore(appStoreUrl),
                  child: const Text('Update'),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  onPressed: () => setState(() => _dismissed = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
