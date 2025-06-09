import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/services/drift_quote_service.dart';
import 'package:quotely_flutter_app/services/http_service.dart';

import '../components/layouts/main_layout.dart';
import '../constants/urls.dart';
import '../dtos/quote_response_dto.dart';

// Enum to manage the different states of the download process
enum DownloadState { initial, downloading, saving, completed, error }

class SettingsOfflineSupportScreen extends StatefulWidget {
  static const kRouteName = '/offline-support';
  const SettingsOfflineSupportScreen({super.key});

  @override
  State<SettingsOfflineSupportScreen> createState() =>
      _SettingsOfflineSupportScreenState();
}

class _SettingsOfflineSupportScreenState
    extends State<SettingsOfflineSupportScreen> {
  DownloadState _state = DownloadState.initial;
  String _feedbackMessage = '';
  String _errorMessage = '';

  Future<void> _startDownloadProcess() async {
    // Prevent starting a new download if one is already in progress
    if (_state == DownloadState.downloading || _state == DownloadState.saving) {
      return;
    }

    setState(() {
      _state = DownloadState.downloading;
      _feedbackMessage = 'Connecting to the server...';
    });

    try {
      // 1. Downloading
      final uri = Uri.parse('$kApiUrl/$kGetAllQuotes?getAllRows=true');
      final Response response = await HttpService.get(uri.toString());

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to connect to server. Status: ${response.statusCode}');
      }

      final quoteResponseDto =
          QuoteResponseDto.fromJson(json.decode(response.data));
      final quotesToSave = quoteResponseDto.quotes;

      // 2. Saving to Database
      setState(() {
        _state = DownloadState.saving;
        _feedbackMessage =
            'Saving ${quotesToSave.length} quotes to your device.\nThis may take a moment, please wait.';
      });

      await DriftQuoteService.saveNewQuotesToDatabase(quotesToSave);

      // 3. Completed
      setState(() {
        _state = DownloadState.completed;
        _feedbackMessage =
            'Success! ${quotesToSave.length} quotes are now available offline.';
      });
    } catch (e) {
      // 4. Error Handling
      setState(() {
        _state = DownloadState.error;
        _errorMessage =
            'An error occurred during the process.\nPlease check your internet connection and try again.\n\nError: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return MainLayout(
      title: 'Offline Support',
      body: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Center(
            // AnimatedSwitcher provides a smooth cross-fade between states
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildContentForState(kPrimaryColor),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the UI based on the current download state
  Widget _buildContentForState(Color kPrimaryColor) {
    switch (_state) {
      case DownloadState.downloading:
      case DownloadState.saving:
        return _buildProgressState(kPrimaryColor);
      case DownloadState.completed:
        return _buildCompletedState(kPrimaryColor);
      case DownloadState.error:
        return _buildErrorState(kPrimaryColor);
      case DownloadState.initial:
        return _buildInitialState(kPrimaryColor);
    }
  }

  Widget _buildInitialState(Color kPrimaryColor) {
    return Column(
      key: const ValueKey('initial'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_download_outlined, size: 100, color: kPrimaryColor),
        const SizedBox(height: 20),
        Text(
          'Enable Offline Access',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        const SizedBox(height: 10),
        const Text(
          'Download all quotes and authors from our server so you can browse them anytime, even without an internet connection.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: _startDownloadProcess,
          icon: const Icon(Icons.download_for_offline, size: 24),
          label: const Text(
            'Download Everything',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressState(Color kPrimaryColor) {
    return Column(
      key: const ValueKey('progress'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          _feedbackMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kPrimaryColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedState(Color kPrimaryColor) {
    return Column(
      key: const ValueKey('completed'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline,
            size: 100, color: Colors.green.shade600),
        const SizedBox(height: 20),
        Text(
          'Download Complete',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _feedbackMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Awesome!', style: TextStyle(fontSize: 16)),
        )
      ],
    );
  }

  Widget _buildErrorState(Color kPrimaryColor) {
    return Column(
      key: const ValueKey('error'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 100, color: Colors.red.shade600),
        const SizedBox(height: 20),
        Text(
          'Something Went Wrong',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 25),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          onPressed: _startDownloadProcess,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again', style: TextStyle(fontSize: 16)),
        )
      ],
    );
  }
}
