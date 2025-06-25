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
    final theme = Theme.of(context);
    final kPrimaryColor = theme.colorScheme.primary;

    return MainLayout(
      title: title,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          children: [
            // Use an Expanded widget to allow the fact component to fill the space
            Expanded(
              child: factWidget,
            ),
            const SizedBox(height: 16),
            // The "See All" button
            GestureDetector(
              onTap: () => context.push(allFactRoute),
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: kPrimaryColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'See All Facts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
