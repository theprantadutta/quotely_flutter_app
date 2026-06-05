import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../database/database.dart';
import '../../service_locator/init_service_locators.dart';
import '../painted_views/shared/content_view_mode.dart';
import '../painted_views/shared/view_mode_button.dart';

class HomeScreenTopBar extends StatelessWidget {
  final bool loading;
  final ContentViewMode mode;
  final VoidCallback onCycleMode;
  final ValueChanged<ContentViewMode> onSelectMode;
  final Future<void> Function() onRefresh;

  const HomeScreenTopBar({
    super.key,
    required this.loading,
    required this.mode,
    required this.onCycleMode,
    required this.onSelectMode,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.06,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (!kDebugMode) return;
                  final db = getIt.get<AppDatabase>();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => DriftDbViewer(db)),
                  );
                },
                child: FaIcon(
                  FontAwesomeIcons.quoteLeft,
                  size: 20,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quotely',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              if (loading)
                LoadingAnimationWidget.hexagonDots(
                  color: kPrimaryColor,
                  size: 20,
                ),
            ],
          ),
          Row(
            children: [
              // Pull-to-refresh only exists in scroll mode; the other modes
              // get an explicit refresh button.
              if (!mode.supportsPullToRefresh) ...[
                ViewRefreshButton(onRefresh: onRefresh),
                const SizedBox(width: 8),
              ],
              ViewModeButton(
                mode: mode,
                onCycle: onCycleMode,
                onSelect: onSelectMode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
