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
import '../components/shared/something_went_wrong.dart';
import '../constants/urls.dart';
import '../dtos/ai_fact_response_dto.dart';
import '../dtos/quote_response_dto.dart';
import '../dtos/tag_response_dto.dart';

// The state enum remains the same
enum DownloadState { initial, processing, completed, error }

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

  // --- NEW state variables for detailed progress ---
  bool _isProcessing = false;
  double _progress = 0.0;
  String _currentStepMessage = '';
  int _totalItemsDownloaded = 0;

  DateTime? _lastDownloadedDate;
  final String _kLastDownloadedKey = 'offline_data_last_downloaded';

  @override
  void initState() {
    super.initState();
    _loadLastDownloadedDate();
  }

  Future<void> _loadLastDownloadedDate() async {
    final preferences = await SharedPreferences.getInstance();
    final dateString = preferences.getString(_kLastDownloadedKey);
    if (dateString != null) {
      if (mounted) {
        setState(() {
          _lastDownloadedDate = DateTime.parse(dateString);
        });
      }
    }
  }

  Future<void> _startDownloadProcess() async {
    // This function remains the same, but we add one line on success.
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _state = DownloadState.processing;
      _progress = 0.0;
      _totalItemsDownloaded = 0;
    });

    try {
      int quoteCount = await _downloadAndSaveQuotes();
      if (!mounted) return;
      setState(() {
        _totalItemsDownloaded += quoteCount;
        _progress = 0.25;
      });

      int authorCount = await _downloadAndSaveAuthors();
      if (!mounted) return;
      setState(() {
        _totalItemsDownloaded += authorCount;
        _progress = 0.50;
      });

      int factCount = await _downloadAndSaveFacts();
      if (!mounted) return;
      setState(() {
        _totalItemsDownloaded += factCount;
        _progress = 0.75;
      });

      int tagCount = await _downloadAndSaveTags();
      if (!mounted) return;
      setState(() {
        _totalItemsDownloaded += tagCount;
        _progress = 1.0;
      });

      // --- NEW: Save the timestamp on success ---
      final preferences = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await preferences.setString(_kLastDownloadedKey, now.toIso8601String());

      if (!mounted) return;
      setState(() {
        _lastDownloadedDate = now; // Update the UI immediately
        _state = DownloadState.completed;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = DownloadState.error;
        _isProcessing = false;
      });
    }
  }

  // Your download helper functions (_downloadAndSaveQuotes, etc.) remain the same.

  // --- NEW: Logic to handle the button press ---
  void _onDownloadButtonPressed() {
    // If data has been downloaded before, show a confirmation dialog.
    if (_lastDownloadedDate != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text(
            'Sync Latest Content?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
              'You already have an offline copy from ${DateFormat('dd MMM, yyyy').format(_lastDownloadedDate!)}. Downloading again will fetch the latest updates.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startDownloadProcess();
              },
              child: const Text('Download Again'),
            ),
          ],
        ),
      );
    } else {
      // If it's the first time, start the download immediately.
      _startDownloadProcess();
    }
  }

  // --- SEPARATE, DEDICATED FUNCTIONS FOR EACH DATA TYPE ---

  Future<int> _downloadAndSaveQuotes() async {
    setState(() => _currentStepMessage = 'Downloading quotes...');
    final uri = Uri.parse('$kApiUrl/$kGetAllQuotes?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch quotes');

    final quoteResponseDto =
        QuoteResponseDto.fromJson(json.decode(response.data));
    final quotesToSave = quoteResponseDto.quotes;

    setState(
        () => _currentStepMessage = 'Saving ${quotesToSave.length} quotes...');
    await DriftQuoteService.saveNewQuotesToDatabase(quotesToSave);
    return quotesToSave.length;
  }

  Future<int> _downloadAndSaveAuthors() async {
    setState(() => _currentStepMessage = 'Downloading authors...');
    final uri = Uri.parse('$kApiUrl/$kGetAllAuthors?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch authors');

    final authorResponseDto =
        AuthorResponseDto.fromJson(json.decode(response.data));
    final authorsToSave = authorResponseDto.authors;

    setState(() =>
        _currentStepMessage = 'Saving ${authorsToSave.length} authors...');
    await DriftAuthorService.saveAuthorsToDatabase(authorsToSave);
    return authorsToSave.length;
  }

  Future<int> _downloadAndSaveFacts() async {
    setState(() => _currentStepMessage = 'Downloading facts...');
    final uri = Uri.parse('$kApiUrl/$kGetAllAiFacts?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch facts');

    final factResponseDto =
        AiFactResponseDto.fromJson(json.decode(response.data));
    final factsToSave = factResponseDto.aiFacts;

    setState(
        () => _currentStepMessage = 'Saving ${factsToSave.length} facts...');
    await DriftFactService.saveNewFactsToDatabase(factsToSave);
    return factsToSave.length;
  }

  Future<int> _downloadAndSaveTags() async {
    setState(() => _currentStepMessage = 'Downloading tags...');
    // The API endpoint is the same
    final uri = Uri.parse('$kApiUrl/$kGetAllTags?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch tags');

    // --- FIX: Use the TagResponseDto to correctly parse the API's object response ---
    // Instead of assuming a raw list, we parse it using the DTO you already have.
    final tagResponseDto = TagResponseDto.fromJson(json.decode(response.data));

    // --- FIX: Get the list of tags from the DTO ---
    final tagsToSave = tagResponseDto.tags;

    setState(() => _currentStepMessage = 'Saving ${tagsToSave.length} tags...');
    await DriftTagService.saveTagsToDatabase(tagsToSave);
    return tagsToSave.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MainLayout(
      title: 'Download Everything',
      body: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildContentForState(theme),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the UI based on the current download state
  Widget _buildContentForState(ThemeData theme) {
    switch (_state) {
      case DownloadState.processing:
        return _buildProgressState(theme);
      case DownloadState.completed:
        return _buildCompletedState(theme);
      case DownloadState.error:
        return _buildErrorState(theme);
      case DownloadState.initial:
        // default:
        return _buildInitialState(theme);
    }
  }

  // --- UPDATED: _buildInitialState is now smarter ---
  Widget _buildInitialState(ThemeData theme) {
    bool hasData = _lastDownloadedDate != null;

    return Container(
      key: const ValueKey('initial'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              hasData
                  ? Icons.cloud_sync_outlined
                  : Icons.cloud_download_outlined,
              size: 60,
              color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            hasData ? 'Offline Data Available' : 'Enable Offline Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasData
                ? 'Last updated on ${DateFormat('dd MMM, yyyy \'at\' hh:mm a').format(_lastDownloadedDate!)}.'
                : 'Download the entire library to enjoy Quotely anywhere, even without an internet connection.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            // The button now calls our new handler function
            onPressed: _onDownloadButtonPressed,
            icon: Icon(
                hasData ? Icons.sync_rounded : Icons.download_for_offline,
                size: 24),
            label: Text(
              hasData ? 'Sync Latest Content' : 'Download Everything',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressState(ThemeData theme) {
    return Container(
      key: const ValueKey('progress'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
                Center(
                  child: Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            _currentStepMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloaded $_totalItemsDownloaded items so far...',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(ThemeData theme) {
    return Container(
      key: const ValueKey('completed'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 60, color: Colors.green.shade600),
          const SizedBox(height: 20),
          Text('Download Complete',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            'Success! $_totalItemsDownloaded total items are now available for offline use.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => setState(() => _state = DownloadState.initial),
            child: const Text('Awesome!', style: TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: SomethingWentWrong(
        onRetryPressed: _startDownloadProcess,
      ),
    );
    // return Container(
    //   key: const ValueKey('error'),
    //   padding: const EdgeInsets.all(24),
    //   decoration: BoxDecoration(
    //     color: theme.colorScheme.errorContainer.withOpacity(0.3),
    //     borderRadius: BorderRadius.circular(20),
    //     border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
    //   ),
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
    //       const SizedBox(height: 20),
    //       Text('Something Went Wrong',
    //           style: theme.textTheme.headlineSmall
    //               ?.copyWith(fontWeight: FontWeight.bold)),
    //       const SizedBox(height: 15),
    //       Text(
    //         _errorMessage,
    //         textAlign: TextAlign.center,
    //         style: theme.textTheme.bodyMedium
    //             ?.copyWith(color: theme.colorScheme.onErrorContainer),
    //       ),
    //       const SizedBox(height: 25),
    //       ElevatedButton.icon(
    //         onPressed: _startDownloadProcess,
    //         icon: const Icon(Icons.refresh),
    //         label: const Text('Try Again', style: TextStyle(fontSize: 16)),
    //       )
    //     ],
    //   ),
    // );
  }
}
