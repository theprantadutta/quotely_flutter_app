import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quotely_flutter_app/dtos/author_response_dto.dart';
import 'package:quotely_flutter_app/services/drift_author_service.dart';
import 'package:quotely_flutter_app/services/drift_fact_service.dart';
import 'package:quotely_flutter_app/services/drift_quote_service.dart';
import 'package:quotely_flutter_app/services/drift_tag_service.dart';
import 'package:quotely_flutter_app/services/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/layouts/main_layout.dart';
import '../constants/urls.dart';
import '../dtos/ai_fact_response_dto.dart';
import '../dtos/quote_response_dto.dart';
import '../dtos/tag_response_dto.dart';

enum DownloadState { initial, processing, completed, error }

enum _StepStatus { pending, active, done }

/// One downloadable content type, tracked live so the UI can show per-category
/// progress instead of a single opaque spinner.
class _DownloadStep {
  final String label;
  final IconData icon;
  _StepStatus status = _StepStatus.pending;
  int count = 0;

  _DownloadStep(this.label, this.icon);
}

class SettingsDownloadEverythingScreen extends StatefulWidget {
  static const kRouteName = '/download-everything';
  const SettingsDownloadEverythingScreen({super.key});

  @override
  State<SettingsDownloadEverythingScreen> createState() =>
      _SettingsDownloadEverythingScreenState();
}

class _SettingsDownloadEverythingScreenState
    extends State<SettingsDownloadEverythingScreen> {
  DownloadState _state = DownloadState.initial;
  bool _isProcessing = false;
  double _progress = 0.0;
  int _totalItemsDownloaded = 0;

  DateTime? _lastDownloadedDate;
  static const String _kLastDownloadedKey = 'offline_data_last_downloaded';

  late final List<_DownloadStep> _steps = [
    _DownloadStep('Quotes', Icons.format_quote_rounded),
    _DownloadStep('Authors', Icons.person_outline_rounded),
    _DownloadStep('Facts', Icons.lightbulb_outline_rounded),
    _DownloadStep('Tags', Icons.sell_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadLastDownloadedDate();
  }

  Future<void> _loadLastDownloadedDate() async {
    final preferences = await SharedPreferences.getInstance();
    final dateString = preferences.getString(_kLastDownloadedKey);
    if (dateString != null && mounted) {
      setState(() => _lastDownloadedDate = DateTime.parse(dateString));
    }
  }

  Future<void> _startDownloadProcess() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _state = DownloadState.processing;
      _progress = 0.0;
      _totalItemsDownloaded = 0;
      for (final step in _steps) {
        step.status = _StepStatus.pending;
        step.count = 0;
      }
    });

    // Each task fetches a content type and persists it to the local database.
    final tasks = <Future<int> Function()>[
      _downloadAndSaveQuotes,
      _downloadAndSaveAuthors,
      _downloadAndSaveFacts,
      _downloadAndSaveTags,
    ];

    try {
      for (var i = 0; i < tasks.length; i++) {
        if (!mounted) return;
        setState(() => _steps[i].status = _StepStatus.active);
        final count = await tasks[i]();
        if (!mounted) return;
        setState(() {
          _steps[i].status = _StepStatus.done;
          _steps[i].count = count;
          _totalItemsDownloaded += count;
          _progress = (i + 1) / tasks.length;
        });
      }

      final preferences = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await preferences.setString(_kLastDownloadedKey, now.toIso8601String());

      if (!mounted) return;
      setState(() {
        _lastDownloadedDate = now;
        _state = DownloadState.completed;
        _isProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = DownloadState.error;
        _isProcessing = false;
      });
    }
  }

  void _onDownloadButtonPressed() {
    // Re-downloading is a confirm step; the first download just starts.
    if (_lastDownloadedDate == null) {
      _startDownloadProcess();
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Sync latest content?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You already have an offline copy from '
          '${DateFormat('dd MMM, yyyy').format(_lastDownloadedDate!)}. '
          'Downloading again fetches the latest updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _startDownloadProcess();
            },
            child: const Text('Download again'),
          ),
        ],
      ),
    );
  }

  // --- Per-type download + persist helpers (return how many were saved) ---

  Future<int> _downloadAndSaveQuotes() async {
    final uri = Uri.parse('$kApiUrl/$kGetAllQuotes?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch quotes');
    final quotes = QuoteResponseDto.fromJson(json.decode(response.data)).quotes;
    await DriftQuoteService.saveNewQuotesToDatabase(quotes);
    return quotes.length;
  }

  Future<int> _downloadAndSaveAuthors() async {
    final uri = Uri.parse('$kApiUrl/$kGetAllAuthors?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch authors');
    final authors = AuthorResponseDto.fromJson(
      json.decode(response.data),
    ).authors;
    await DriftAuthorService.saveAuthorsToDatabase(authors);
    return authors.length;
  }

  Future<int> _downloadAndSaveFacts() async {
    final uri = Uri.parse('$kApiUrl/$kGetAllAiFacts?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch facts');
    final facts = AiFactResponseDto.fromJson(
      json.decode(response.data),
    ).aiFacts;
    await DriftFactService.saveNewFactsToDatabase(facts);
    return facts.length;
  }

  Future<int> _downloadAndSaveTags() async {
    final uri = Uri.parse('$kApiUrl/$kGetAllTags?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch tags');
    final tags = TagResponseDto.fromJson(json.decode(response.data)).tags;
    await DriftTagService.saveTagsToDatabase(tags);
    return tags.length;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Download Everything',
      body: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: _buildContentForState(Theme.of(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildContentForState(ThemeData theme) {
    switch (_state) {
      case DownloadState.processing:
        return _buildProgressState(theme);
      case DownloadState.completed:
        return _buildCompletedState(theme);
      case DownloadState.error:
        return _buildErrorState(theme);
      case DownloadState.initial:
        return _buildInitialState(theme);
    }
  }

  // --- Reusable pieces ---

  /// A rounded card wrapper matching the app's surface styling.
  Widget _card({required Key key, required Widget child, Color? border}) {
    final theme = Theme.of(context);
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              border ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }

  /// A circular icon badge in the primary tint.
  Widget _iconBadge(IconData icon, ThemeData theme, {Color? color}) {
    final c = color ?? theme.colorScheme.primary;
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: 40, color: c),
    );
  }

  /// One content-type row with a live status trailing widget.
  Widget _stepTile(_DownloadStep step, ThemeData theme) {
    final done = step.status == _StepStatus.done;
    final active = step.status == _StepStatus.active;
    final accent = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget trailing;
    if (done) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${step.count}',
            style: TextStyle(fontWeight: FontWeight.w700, color: muted),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade600,
            size: 22,
          ),
        ],
      );
    } else if (active) {
      trailing = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: accent),
      );
    } else {
      // Pending: a quiet "queued" hint — deliberately NOT a radio/checkbox
      // glyph so it doesn't read as a tappable control.
      trailing = Icon(
        Icons.more_horiz_rounded,
        size: 20,
        color: muted.withValues(alpha: 0.4),
      );
    }

    final iconColor = done || active ? accent : muted.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(step.icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: active || done ? theme.colorScheme.onSurface : muted,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  // --- States ---

  Widget _buildInitialState(ThemeData theme) {
    final hasData = _lastDownloadedDate != null;
    return _card(
      key: const ValueKey('initial'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge(
            hasData ? Icons.cloud_done_outlined : Icons.cloud_download_outlined,
            theme,
          ),
          const SizedBox(height: 20),
          Text(
            hasData ? 'Offline data ready' : 'Enable offline access',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasData
                ? 'Last updated ${DateFormat('dd MMM, yyyy \'at\' h:mm a').format(_lastDownloadedDate!)}.'
                : 'Save the whole library to your device so Quotely works anywhere — even offline.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          // Preview of everything that gets saved.
          ...List.generate(_steps.length, (i) => _stepTile(_steps[i], theme)),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _onDownloadButtonPressed,
              icon: Icon(hasData ? Icons.sync_rounded : Icons.download_rounded),
              label: Text(
                hasData ? 'Sync latest content' : 'Download everything',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressState(ThemeData theme) {
    return _card(
      key: const ValueKey('progress'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 7,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
                Center(
                  child: Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Saving your library…',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(_steps.length, (i) => _stepTile(_steps[i], theme)),
          const SizedBox(height: 14),
          Text(
            '$_totalItemsDownloaded items saved so far',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(ThemeData theme) {
    final green = Colors.green.shade600;
    return _card(
      key: const ValueKey('completed'),
      border: green.withValues(alpha: 0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge(Icons.check_circle_rounded, theme, color: green),
          const SizedBox(height: 20),
          Text(
            'You\'re all set',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$_totalItemsDownloaded items are now available offline.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_steps.length, (i) => _stepTile(_steps[i], theme)),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => setState(() => _state = DownloadState.initial),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    final failed = _steps.firstWhere(
      (s) => s.status == _StepStatus.active,
      orElse: () => _steps.first,
    );
    return _card(
      key: const ValueKey('error'),
      border: theme.colorScheme.error.withValues(alpha: 0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBadge(
            Icons.cloud_off_rounded,
            theme,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 20),
          Text(
            'Download interrupted',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We couldn\'t finish downloading ${failed.label.toLowerCase()}. '
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _startDownloadProcess,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Try again',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
