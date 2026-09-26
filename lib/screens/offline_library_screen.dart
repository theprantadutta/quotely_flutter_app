import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/thread/thread.dart';
import '../constants/shared_preference_keys.dart';
import '../constants/urls.dart';
import '../dtos/ai_fact_response_dto.dart';
import '../dtos/author_response_dto.dart';
import '../dtos/quote_response_dto.dart';
import '../dtos/tag_response_dto.dart';
import '../navigation/routes.dart';
import '../service_locator/init_service_locators.dart';
import '../services/drift_author_service.dart';
import '../services/drift_fact_service.dart';
import '../services/drift_quote_service.dart';
import '../services/drift_tag_service.dart';
import '../services/http_service.dart';
import '../services/scene_repository.dart';

/// The downloadable packs, in display order.
enum OfflinePack {
  quotes('Quotes', 'quotes'),
  authors('Authors', 'people'),
  facts('Facts', 'facts'),
  scenes('Scenes', 'lines');

  final String label;
  final String unit;
  const OfflinePack(this.label, this.unit);
}

/// Saved item counts per pack (null = never downloaded).
Future<Map<OfflinePack, int?>> offlinePackCounts() async {
  final prefs = await SharedPreferences.getInstance();
  // Installs that downloaded before packs existed had one "everything" date.
  final legacy = prefs.getString('offline_data_last_downloaded') != null;
  return {
    for (final p in OfflinePack.values)
      p:
          prefs.getInt('$kOfflinePackCountPrefix${p.name}') ??
          (legacy && p != OfflinePack.scenes ? 0 : null),
  };
}

/// Share of packs downloaded, 0–1 (You → "62% downloaded").
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
  static const _kLastDownloadedKey = 'offline_data_last_downloaded';

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
    final last = prefs.getString(_kLastDownloadedKey);
    if (!mounted) return;
    setState(() {
      _counts.addAll(counts);
      for (final e in counts.entries) {
        if (e.value != null) _states[e.key] = _PackState.saved;
      }
      _wifiOnly = prefs.getBool(kWifiOnlyKey) ?? true;
      _lastDownloaded = last == null ? null : DateTime.tryParse(last);
    });
  }

  Future<bool> _networkAllowed() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      _snack('You’re offline. Connect to the internet to download.');
      return false;
    }
    final unmetered =
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    if (_wifiOnly && !unmetered) {
      _snack('Wi-Fi only is on. Connect to Wi-Fi, or turn it off below.');
      return false;
    }
    return true;
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  // --- Per-pack download + persist (return how many items were saved) ----

  Future<int> _downloadQuotes() async {
    final response = await HttpService.get(
      '$kApiUrl/$kGetAllQuotes?getAllRows=true',
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch quotes');
    final quotes = QuoteResponseDto.fromJson(json.decode(response.data)).quotes;
    await DriftQuoteService.saveNewQuotesToDatabase(quotes);
    // Tags ride along with quotes (they power the Topics chips offline).
    final tagResponse = await HttpService.get(
      '$kApiUrl/$kGetAllTags?getAllRows=true',
    );
    if (tagResponse.statusCode == 200) {
      final tags = TagResponseDto.fromJson(json.decode(tagResponse.data)).tags;
      await DriftTagService.saveTagsToDatabase(tags);
    }
    return quotes.length;
  }

  Future<int> _downloadAuthors() async {
    final response = await HttpService.get(
      '$kApiUrl/$kGetAllAuthors?getAllRows=true',
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch authors');
    final authors = AuthorResponseDto.fromJson(
      json.decode(response.data),
    ).authors;
    await DriftAuthorService.saveAuthorsToDatabase(authors);
    return authors.length;
  }

  Future<int> _downloadFacts() async {
    final response = await HttpService.get(
      '$kApiUrl/$kGetAllAiFacts?getAllRows=true',
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch facts');
    final facts = AiFactResponseDto.fromJson(
      json.decode(response.data),
    ).aiFacts;
    await DriftFactService.saveNewFactsToDatabase(facts);
    return facts.length;
  }

  Future<int> _downloadScenes() => SceneRepository.instance.downloadAll();

  Future<int> Function() _task(OfflinePack p) => switch (p) {
    OfflinePack.quotes => _downloadQuotes,
    OfflinePack.authors => _downloadAuthors,
    OfflinePack.facts => _downloadFacts,
    OfflinePack.scenes => _downloadScenes,
  };

  Future<bool> _download(OfflinePack pack, {bool checkNetwork = true}) async {
    if (checkNetwork && !await _networkAllowed()) return false;
    setState(() => _states[pack] = _PackState.downloading);
    try {
      final count = await _task(pack)();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$kOfflinePackCountPrefix${pack.name}', count);
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
    if (_busy || !await _networkAllowed()) return;
    getIt.get<FirebaseAnalytics>().logEvent(name: 'offline_download_started');
    var ok = true;
    for (final pack in OfflinePack.values) {
      if (!mounted) return;
      ok = await _download(pack, checkNetwork: false) && ok;
    }
    final now = DateTime.now();
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastDownloadedKey, now.toIso8601String());
    }
    if (!mounted) return;
    setState(() => _lastDownloaded = ok ? now : _lastDownloaded);
    _snack(
      ok
          ? 'Everything is saved for offline reading.'
          : 'Some packs didn’t finish. Check your connection and try again.',
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
