import 'package:flutter/material.dart';

import '../components/layouts/main_layout.dart';
import '../services/common_service.dart';

class SettingsOfflineSupportScreen extends StatelessWidget {
  static const kRouteName = '/offline-support';
  const SettingsOfflineSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return MainLayout(
      title: 'Offline Support',
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.87,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.cloud_download_outlined,
                  size: 100,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Use Offline Support',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.8,
                child: const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Download all quotes and authors from our server so you don\'t have to have internet connection to read quotes',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: CommonService.showNotImplementedDialog(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: kPrimaryColor,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      'Download Everything',
                      style: TextStyle(
                        fontSize: 15,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
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
}
