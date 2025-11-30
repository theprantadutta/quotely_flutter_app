// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadProgressDialog extends StatefulWidget {
  final String downloadUrl;
  final String savePath;
  final Dio dio;

  const DownloadProgressDialog({
    super.key,
    required this.downloadUrl,
    required this.savePath,
    required this.dio,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double progress = 0.0;
  int receivedBytes = 0;
  int totalBytes = 0;
  int retryCount = 0;
  final int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _requestInstallPackagesPermission() async {
    // Check if the permission is already granted
    if (await Permission.requestInstallPackages.isGranted) {
      // Permission already granted, proceed with installation
      return;
    }

    // Request the permission
    var status = await Permission.requestInstallPackages.request();

    if (status.isGranted) {
      // Permission granted, proceed with installation
      return;
    } else if (status.isDenied) {
      // Permission denied, show a message or prompt
      debugPrint(
        'Permission denied. You need this permission to install apps.',
      );
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, direct user to app settings
      debugPrint(
        'Permission permanently denied. Please enable it from settings.',
      );
      await openAppSettings(); // Open app settings to manually grant the permission
    }
  }

  Future<void> _startDownload() async {
    try {
      await widget.dio.download(
        widget.downloadUrl,
        widget.savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              receivedBytes = received;
              totalBytes = total;
              progress = received / total;
            });
          }
        },
      );
      Navigator.of(context).pop();
      _showDownloadCompletedDialog();
    } catch (e) {
      retryCount++;
      if (retryCount < maxRetries) {
        _showRetryDialog();
      } else {
        Navigator.of(context).pop();
        _showDownloadFailedDialog();
      }
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Download Failed'),
          content: Text(
            'Failed to download the update. Retrying... ($retryCount/$maxRetries)',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry Now'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _startDownload(); // Retry download
              },
            ),
            TextButton(
              child: const Text('Exit'),
              onPressed: () async {
                Navigator.of(context).pop();
                await FlutterExitApp.exitApp();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDownloadFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Download Failed'),
          content: const Text(
            'Failed to download the update after multiple attempts. Please try again later.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Exit'),
              onPressed: () async {
                await FlutterExitApp.exitApp();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDownloadCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Download Complete 🚀'),
          content: const Text(
            'The app has been downloaded successfully. You can now install it.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Install Now'),
              onPressed: () async {
                await _requestInstallPackagesPermission();
                // Now proceed with opening the APK file for installation
                OpenFile.open(widget.savePath);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String downloadedSize = (receivedBytes / (1024 * 1024)).toStringAsFixed(
      2,
    ); // Convert to MB
    String totalSize = (totalBytes / (1024 * 1024)).toStringAsFixed(
      2,
    ); // Convert to MB
    final kPrimaryColor = Theme.of(context).primaryColor;
    return AlertDialog(
      title: const Text('Downloading Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 2.0,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      kPrimaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 2.0,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.0,
                    color: kPrimaryColor,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Downloading $downloadedSize MB / $totalSize MB'),
          const SizedBox(height: 16),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel & Exit'),
          onPressed: () async {
            Navigator.of(context).pop();
            widget.dio.close();
            await FlutterExitApp.exitApp();
          },
        ),
      ],
    );
  }
}
