import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/thread/thread.dart';
import '../constants/shared_preference_keys.dart';
import '../navigation/routes.dart';
import '../service_locator/init_service_locators.dart';
import '../services/library_sync.dart';

export '../services/library_sync.dart' show OfflinePack;

/// Saved item counts per pack (null = never downloaded).
Future<Map<OfflinePack, int?>> offlinePackCounts() => LibrarySync.packCounts();

/// Share of packs downloaded, 0-1 (You: "62% downloaded").
Future<double> offlineLibraryProgress() async {
  final counts = await offlinePackCounts();
  return counts.values.where((c) => c != null).length /
      OfflinePack.values.length;
}

enum _PackState { idle, downloading, saved, failed }

class OfflineLibraryScreen extends StatefulWidget {
  static const kRouteName = Routes.offlineLibrary;
  const OfflineLibraryScreen({super.key});

  @override
  State<OfflineLibraryScreen> createState() => _OfflineLibraryScreenState();
}

class _OfflineLibraryScreenState extends State<OfflineLibraryScreen> {
  final Map<OfflinePack, int?> _counts = {};
  final Map<OfflinePack, _PackState> _states = {
    for (final p in OfflinePack.values) p: _PackState.idle,
  };
  bool _wifiOnly = true;
  DateTime? _lastDownloaded;

  bool get _busy => _states.values.contains(_PackState.downloading);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final counts = await offlinePackCounts();
    final last = await LibrarySync.lastSynced();
    if (!mounted) return;
    setState(() {
      _counts.addAll(counts);
      for (final e in counts.entries) {
        if (e.value != null) _states[e.key] = _PackState.saved;
      }
      _wifiOnly = prefs.getBool(kWifiOnlyKey) ?? true;
      _lastDownloaded = last;
    });
  }

  Future<bool> _networkAllowed() async {
    switch (await LibrarySync.networkBlock()) {
      case SyncBlock.offline:
        _snack('You\u2019re offline. Connect to the internet to download.');
        return false;
      case SyncBlock.wifiOnly:
        _snack('Wi-Fi only is on. Connect to Wi-Fi, or turn it off below.');
        return false;
      case SyncBlock.none:
        return true;
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<bool> _download(OfflinePack pack) async {
    if (!await _networkAllowed()) return false;
    setState(() => _states[pack] = _PackState.downloading);
    try {
      final count = await LibrarySync.downloadPack(pack);
      if (!mounted) return true;
      setState(() {
        _counts[pack] = count;
        _states[pack] = _PackState.saved;
      });
      return true;
    } catch (_) {
      if (mounted) setState(() => _states[pack] = _PackState.failed);
      return false;
    }
  }

  Future<void> _downloadEverything() async {
    if (_busy || LibrarySync.running || !await _networkAllowed()) return;
    getIt.get<FirebaseAnalytics>().logEvent(name: 'offline_download_started');
    final ok = await LibrarySync.downloadAll(
      onPack: (pack, count) {
        if (!mounted) return;
        setState(() {
          if (count == null) {
            _states[pack] = _PackState.downloading;
          } else if (count < 0) {
            _states[pack] = _PackState.failed;
          } else {
            _counts[pack] = count;
            _states[pack] = _PackState.saved;
          }
        });
      },
    );
    final last = await LibrarySync.lastSynced();
    if (!mounted) return;
    setState(() => _lastDownloaded = last);
    _snack(
      ok
          ? 'Everything is saved for offline reading.'
          : 'Some packs didn\u2019t finish. Check your connection and try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final saved = _counts.values.where((c) => c != null).length;
    final progress = saved / OfflinePack.values.length;
    final items = _counts.values.fold<int>(0, (a, c) => a + (c ?? 0));
    final allSaved = saved == OfflinePack.values.length;

    return ThreadPage(
      title: 'Offline library',
      bottom: PrimaryButton(
        label: _busy
            ? 'Saving…'
            : allSaved
            ? 'Sync latest content'
            : 'Download everything',
        loading: _busy,
        icon: allSaved ? Icons.sync_rounded : Icons.download_rounded,
        onPressed: _downloadEverything,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          QCard(
            radius: 26,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: context.qt.titleScreen.copyWith(
                        fontSize: 30,
                        letterSpacing: 30 * -0.04,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$saved of ${OfflinePack.values.length} packs · '
                      '${NumberFormat.compact().format(items)} items',
                      style: context.qt.meta.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                QProgressBar(value: progress),
                const SizedBox(height: 12),
                Text(
                  _lastDownloaded == null
                      ? 'Read everything on a plane, in the subway, anywhere. Downloaded items stay in sync when you’re back online.'
                      : 'Last synced ${DateFormat('d MMM y, h:mm a').format(_lastDownloaded!)}. Downloaded items stay in sync when you’re back online.',
                  style: context.qt.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GroupedList(
            children: [
              for (final pack in OfflinePack.values)
                GroupedRow(
                  title: pack.label,
                  isNew: pack == OfflinePack.scenes,
                  description: _counts[pack] == null
                      ? (pack == OfflinePack.scenes
                            ? 'Titles, characters and lines'
                            : 'Not downloaded')
                      : '${NumberFormat.decimalPattern().format(_counts[pack])} ${pack.unit}',
                  trailing: _trailing(pack, t),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GroupedList(
            children: [
              GroupedRow(
                title: 'Wi-Fi only',
                description: 'Don’t use mobile data',
                trailing: QToggle(
                  value: _wifiOnly,
                  semanticLabel: 'Wi-Fi only',
                  onChanged: (v) async {
                    setState(() => _wifiOnly = v);
                    await (await SharedPreferences.getInstance()).setBool(
                      kWifiOnlyKey,
                      v,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Images aren’t downloaded; portraits and posters load when you’re online.',
            textAlign: TextAlign.center,
            style: context.qt.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _trailing(OfflinePack pack, QuotelyTokens t) {
    switch (_states[pack]!) {
      case _PackState.downloading:
        return Text('Saving…', style: context.qt.chip.copyWith(color: t.mute));
      case _PackState.saved:
        return SoftPill(
          'Saved',
          icon: Icons.check_rounded,
          onTap: _busy ? null : () => _download(pack),
        );
      case _PackState.failed:
      case _PackState.idle:
        return Semantics(
          button: true,
          label: 'Get ${pack.label}',
          excludeSemantics: true,
          child: HitTarget(
            onTap: _busy ? null : () => _download(pack),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: t.acc,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _states[pack] == _PackState.failed ? 'Retry' : 'Get',
                style: context.qt.chip.copyWith(
                  color: t.onAcc,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
    }
  }
}
