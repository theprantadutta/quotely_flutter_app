import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../database/database.dart';
import '../../service_locator/init_service_locators.dart';
import '../shared/top_navigation_bar.dart';

class HomeScreenTopBar extends StatelessWidget {
  final bool loading;

  const HomeScreenTopBar({super.key, required this.loading});

  @override
  Widget build(BuildContext context) {
    return TopNavigationBar(
      title: 'Quotely',
      icon: Icons.format_quote_rounded,
      // Debug-only Drift DB viewer behind the logo badge.
      onIconTap: () {
        if (!kDebugMode) return;
        final db = getIt.get<AppDatabase>();
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => DriftDbViewer(db)));
      },
      trailing: loading
          ? LoadingAnimationWidget.hexagonDots(
              color: Theme.of(context).primaryColor,
              size: 20,
            )
          : null,
    );
  }
}
