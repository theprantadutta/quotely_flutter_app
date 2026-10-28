import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/app_navigation.dart';
import '../navigation/routes.dart';
import '../riverpods/application_info_provider.dart';
import '../theme/app_theme.dart';
import 'thread/q_controls.dart';
import 'thread/spotlight.dart';

/// Honours the admin dashboard's Maintenance mode (ApplicationInfo
/// .maintenanceBreak). While it is on, a full-screen notice covers the app;
/// the reader can check again or keep reading what they saved, which works
/// offline. The setting is re-read whenever the app returns to the foreground,
/// so turning maintenance off releases readers without a restart.
///
/// Sits in MaterialApp.builder, above the router, so it covers every screen.
/// A failed or empty settings fetch never blocks the app.
class MaintenanceGate extends ConsumerStatefulWidget {
  final Widget child;

  const MaintenanceGate({super.key, required this.child});

  @override
  ConsumerState<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends ConsumerState<MaintenanceGate> {
  late final AppLifecycleListener _lifecycle;

  /// The reader chose to keep reading saved items; reset when maintenance ends.
  bool _readingSaved = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(fetchApplicationInfoProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _readSaved() {
    setState(() => _readingSaved = true);
    AppNavigation.router.go(Routes.saved);
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(fetchApplicationInfoProvider);
    final inMaintenance = info.value?.maintenanceBreak ?? false;

    if (!inMaintenance && _readingSaved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _readingSaved = false);
      });
    }

    return Stack(
      children: [
        widget.child,
        if (inMaintenance && !_readingSaved)
          Positioned.fill(
            child: _MaintenanceNotice(
              checking: info.isLoading,
              onCheckAgain: () => ref.invalidate(fetchApplicationInfoProvider),
              onReadSaved: _readSaved,
            ),
          ),
      ],
    );
  }
}

/// The notice itself, laid out like a Today entry: mono eyebrow, a large
/// serif line, a quiet paragraph, then the actions.
class _MaintenanceNotice extends StatelessWidget {
  final bool checking;
  final VoidCallback onCheckAgain;
  final VoidCallback onReadSaved;

  const _MaintenanceNotice({
    required this.checking,
    required this.onCheckAgain,
    required this.onReadSaved,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    return Material(
      type: MaterialType.transparency,
      child: PageBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                Text(
                  'QUOTELY · MAINTENANCE',
                  style: qt.overline.copyWith(color: t.ink),
                ),
                const SizedBox(height: 22),
                Text(
                  "We'll be right back.",
                  style: qt.quoteSpotlight.copyWith(color: t.ink),
                ),
                const SizedBox(height: 20),
                Text(
                  "We're tidying up the library. Everything you've saved "
                  'is still here, and it works offline.',
                  style: qt.body.copyWith(color: t.mute),
                ),
                const Spacer(flex: 4),
                PrimaryButton(
                  label: 'Check again',
                  loading: checking,
                  onPressed: onCheckAgain,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Read what you saved',
                  icon: Icons.bookmark_outline_rounded,
                  onPressed: onReadSaved,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
