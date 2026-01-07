import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quotely_flutter_app/dtos/author_response_dto.dart';
import 'package:quotely_flutter_app/services/drift_author_service.dart';
import 'package:quotely_flutter_app/services/drift_fact_service.dart';
import 'package:quotely_flutter_app/services/drift_quote_service.dart';
import 'package:quotely_flutter_app/services/drift_tag_service.dart';
import 'package:quotely_flutter_app/services/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/shared/something_went_wrong.dart';
import '../constants/urls.dart';
import '../dtos/ai_fact_response_dto.dart';
import '../dtos/quote_response_dto.dart';
import '../dtos/tag_response_dto.dart';
import '../theme/colors/app_colors.dart';
import '../theme/gradients/app_gradients.dart';

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

      final preferences = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await preferences.setString(_kLastDownloadedKey, now.toIso8601String());

      if (!mounted) return;
      setState(() {
        _lastDownloadedDate = now;
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

  void _onDownloadButtonPressed() {
    HapticFeedback.mediumImpact();
    if (_lastDownloadedDate != null) {
      _showSyncDialog();
    } else {
      _startDownloadProcess();
    }
  }

  void _showSyncDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Sync Latest Content?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        content: Text(
          'You already have an offline copy from ${DateFormat('dd MMM, yyyy').format(_lastDownloadedDate!)}. Downloading again will fetch the latest updates.',
          style: GoogleFonts.lora(
            fontSize: 14,
            color: colors.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.lora(color: colors.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _startDownloadProcess();
            },
            child: Text(
              'Download Again',
              style: GoogleFonts.lora(color: colors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _downloadAndSaveQuotes() async {
    setState(() => _currentStepMessage = 'Downloading quotes...');
    final uri = Uri.parse('$kApiUrl/$kGetAllQuotes?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch quotes');

    final quoteResponseDto = QuoteResponseDto.fromJson(
      json.decode(response.data),
    );
    final quotesToSave = quoteResponseDto.quotes;

    setState(
      () => _currentStepMessage = 'Saving ${quotesToSave.length} quotes...',
    );
    await DriftQuoteService.saveNewQuotesToDatabase(quotesToSave);
    return quotesToSave.length;
  }

  Future<int> _downloadAndSaveAuthors() async {
    setState(() => _currentStepMessage = 'Downloading authors...');
    final uri = Uri.parse('$kApiUrl/$kGetAllAuthors?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch authors');

    final authorResponseDto = AuthorResponseDto.fromJson(
      json.decode(response.data),
    );
    final authorsToSave = authorResponseDto.authors;

    setState(
      () => _currentStepMessage = 'Saving ${authorsToSave.length} authors...',
    );
    await DriftAuthorService.saveAuthorsToDatabase(authorsToSave);
    return authorsToSave.length;
  }

  Future<int> _downloadAndSaveFacts() async {
    setState(() => _currentStepMessage = 'Downloading facts...');
    final uri = Uri.parse('$kApiUrl/$kGetAllAiFacts?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch facts');

    final factResponseDto = AiFactResponseDto.fromJson(
      json.decode(response.data),
    );
    final factsToSave = factResponseDto.aiFacts;

    setState(
      () => _currentStepMessage = 'Saving ${factsToSave.length} facts...',
    );
    await DriftFactService.saveNewFactsToDatabase(factsToSave);
    return factsToSave.length;
  }

  Future<int> _downloadAndSaveTags() async {
    setState(() => _currentStepMessage = 'Downloading tags...');
    final uri = Uri.parse('$kApiUrl/$kGetAllTags?getAllRows=true');
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Failed to fetch tags');

    final tagResponseDto = TagResponseDto.fromJson(json.decode(response.data));
    final tagsToSave = tagResponseDto.tags;

    setState(() => _currentStepMessage = 'Saving ${tagsToSave.length} tags...');
    await DriftTagService.saveTagsToDatabase(tagsToSave);
    return tagsToSave.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.scaffoldBackground(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, colors, isDark),

              // Content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _buildContentForState(colors, isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          _NeumorphicBackButton(
            colors: colors,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.warmPrimary(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.cloud_download_rounded,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Mode',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Download for offline access',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentForState(AppColorScheme colors, bool isDark) {
    switch (_state) {
      case DownloadState.processing:
        return _buildProgressState(colors, isDark);
      case DownloadState.completed:
        return _buildCompletedState(colors, isDark);
      case DownloadState.error:
        return _buildErrorState(colors);
      case DownloadState.initial:
        return _buildInitialState(colors, isDark);
    }
  }

  Widget _buildInitialState(AppColorScheme colors, bool isDark) {
    bool hasData = _lastDownloadedDate != null;

    return Container(
      key: const ValueKey('initial'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.15),
                  colors.primaryDark.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasData ? Icons.cloud_sync_rounded : Icons.cloud_download_rounded,
              size: 40,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasData ? 'Offline Data Available' : 'Enable Offline Access',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasData
                ? 'Last updated on ${DateFormat('dd MMM, yyyy \'at\' hh:mm a').format(_lastDownloadedDate!)}.'
                : 'Download the entire library to enjoy Quotely anywhere, even without an internet connection.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 14,
              height: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 28),
          _NeumorphicDownloadButton(
            label: hasData ? 'Sync Latest Content' : 'Download Everything',
            icon: hasData ? Icons.sync_rounded : Icons.download_for_offline,
            colors: colors,
            isDark: isDark,
            onTap: _onDownloadButtonPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressState(AppColorScheme colors, bool isDark) {
    return Container(
      key: const ValueKey('progress'),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  backgroundColor: colors.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
                Center(
                  child: Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _currentStepMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloaded $_totalItemsDownloaded items so far...',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(AppColorScheme colors, bool isDark) {
    return Container(
      key: const ValueKey('completed'),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Download Complete!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Success! $_totalItemsDownloaded total items are now available for offline use.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 14,
              height: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 28),
          _NeumorphicDownloadButton(
            label: 'Awesome!',
            icon: Icons.celebration_rounded,
            colors: colors,
            isDark: isDark,
            onTap: () => setState(() => _state = DownloadState.initial),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppColorScheme colors) {
    return Center(
      child: SomethingWentWrong(
        title: 'Download failed',
        onRetryPressed: _startDownloadProcess,
      ),
    );
  }
}

class _NeumorphicBackButton extends StatefulWidget {
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _NeumorphicBackButton({
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NeumorphicBackButton> createState() => _NeumorphicBackButtonState();
}

class _NeumorphicBackButtonState extends State<_NeumorphicBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.5 : 0.25),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: widget.colors.shadowLight
                        .withValues(alpha: widget.isDark ? 0.08 : 0.7),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: widget.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NeumorphicDownloadButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _NeumorphicDownloadButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NeumorphicDownloadButton> createState() =>
      _NeumorphicDownloadButtonState();
}

class _NeumorphicDownloadButtonState extends State<_NeumorphicDownloadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isPressed
                ? [widget.colors.primaryDark, widget.colors.primary]
                : [widget.colors.primary, widget.colors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.primary.withValues(alpha: 0.4),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 22,
              color: widget.colors.onPrimary,
            ),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: GoogleFonts.lora(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
