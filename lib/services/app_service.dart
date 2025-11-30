// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quotely_flutter_app/util/show_a_toast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/home_screen/download_progress_dialog.dart';

class AppService {
  static void showUpdateDialog(BuildContext context, String downloadVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: const Text(
            'A new version of the app is available. Please update to the latest version to continue.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Update Now'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                if (Platform.isAndroid) {
                  try {
                    await downloadAndUpdate(
                      context,
                      downloadVersion,
                    ); // Start the download
                  } catch (e) {
                    debugPrint('Failed to download the app');
                    debugPrint(e.toString());
                    await FlutterExitApp.exitApp();
                  }
                  return;
                }
                final Uri url = Uri.parse('https://apple.com');
                try {
                  final bool canLaunch = await canLaunchUrl(url);
                  if (canLaunch) {
                    final bool launched = await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched) {
                      showErrorToast(
                        context: context,
                        title: 'Something Went Wrong',
                        description: 'Failed to open $url',
                      );
                    }
                  } else {
                    showErrorToast(
                      context: context,
                      title: 'Something Went Wrong',
                      description: 'Failed to open $url',
                    );
                  }
                } catch (e) {
                  debugPrint('Failed to open the app');
                  debugPrint(e.toString());
                  showErrorToast(
                    context: context,
                    title: 'Something Went Wrong',
                    description: 'Failed to open $url',
                  );
                }
              },
            ),
            TextButton(
              child: const Text('Exit'),
              onPressed: () => FlutterExitApp.exitApp(),
            ),
          ],
        );
      },
    );
  }

  static Future<void> downloadAndUpdate(
    BuildContext context,
    String downloadVersion,
  ) async {
    Dio dio = Dio();
    String appName = 'quotely.apk';
    String downloadUrl =
        'https://github.com/theprantadutta/quotely_flutter_app/releases/download/v$downloadVersion/$appName';
    debugPrint('Download URL: $downloadUrl');
    String savePath = '${(await getExternalStorageDirectory())!.path}/$appName';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DownloadProgressDialog(
          downloadUrl: downloadUrl,
          savePath: savePath,
          dio: dio,
        );
      },
    );
  }

  static Future<void> showMaintenanceDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        final kPrimaryColor = Theme.of(context).primaryColor;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20,
            ), // Rounded corners for modern look
          ),
          backgroundColor: Colors.white, // Set background color
          title: Column(
            children: [
              Icon(
                Icons.construction_outlined,
                size: 60,
                color: Colors.orangeAccent,
              ),
              SizedBox(height: 12),
              Text(
                'We Are Under Maintenance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min, // Ensure dialog height is based on content
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '''
      We're working hard to improve your experience and will be back shortly.
      Thank you for your patience and understanding!
      ''',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment:
              MainAxisAlignment.center, // Center the action button
          actions: [
            SizedBox(
              width: 100, // Set button width
              child: ElevatedButton(
                onPressed: FlutterExitApp.exitApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor.withValues(alpha: 0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded button
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Exit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
