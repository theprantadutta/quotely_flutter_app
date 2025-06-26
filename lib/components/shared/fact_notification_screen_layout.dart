import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layouts/main_layout.dart';

class FactNotificationScreenLayout extends StatelessWidget {
  final String title;
  final Widget factWidget;
  final String allFactRoute;

  const FactNotificationScreenLayout({
    super.key,
    required this.title,
    required this.factWidget,
    required this.allFactRoute,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return MainLayout(
      title: title,
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
        child: Column(
          children: [
            factWidget,
            GestureDetector(
              onTap: () => context.push(allFactRoute),
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.05,
                margin: const EdgeInsets.only(top: 8, bottom: 5),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: kPrimaryColor.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'See All $title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
