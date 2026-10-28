import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../navigation/app_navigation.dart';
import '../navigation/routes.dart';
import '../riverpods/scene_providers.dart';
import '../riverpods/today_quote_of_the_day_provider.dart';
import '../services/quote_widget_service.dart';

/// Connects the app to the Quote of the Day home-screen widget:
/// - whenever today's quote (or the day's scene poster) loads, it is saved
///   for the widget, which then redraws;
/// - when the app goes to the background it is saved again, so the widget
///   catches up with anything the app loaded meanwhile;
/// - a tap on the widget opens the Today screen.
///
/// Sits in MaterialApp.builder next to MaintenanceGate. Does nothing on
/// platforms without the widget.
class QuoteWidgetBridge extends ConsumerStatefulWidget {
  final Widget child;

  const QuoteWidgetBridge({super.key, required this.child});

  @override
  ConsumerState<QuoteWidgetBridge> createState() => _QuoteWidgetBridgeState();
}

class _QuoteWidgetBridgeState extends ConsumerState<QuoteWidgetBridge> {
  AppLifecycleListener? _lifecycle;
  StreamSubscription<Uri?>? _clicks;

  @override
  void initState() {
    super.initState();
    if (!QuoteWidgetService.supported) return;
    _lifecycle = AppLifecycleListener(onHide: () => _sync(force: true));
    ref.listenManual(fetchTodayQuoteOfTheDayProvider, (_, next) {
      if (next.hasValue) _sync();
    }, fireImmediately: true);
    ref.listenManual(sceneOfTheDayProvider, (_, next) {
      if (!next.isLoading) _sync();
    }, fireImmediately: true);
    HomeWidget.initiallyLaunchedFromHomeWidget().then(
      _openedFromWidget,
      onError: (Object _) {},
    );
    _clicks = HomeWidget.widgetClicked.listen(
      _openedFromWidget,
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _clicks?.cancel();
    super.dispose();
  }

  void _sync({bool force = false}) {
    final quote = ref.read(fetchTodayQuoteOfTheDayProvider).value;
    if (quote == null) return;
    final scene = ref.read(sceneOfTheDayProvider);
    // The poster usually lands just after the quote. Wait for it rather than
    // drawing the plain page first; its own listener calls back here.
    if (scene.isLoading && !scene.hasValue) return;
    QuoteWidgetService.instance.update(
      quote: quote,
      posterUrl: scene.value?.sceneQuote.posterUrl,
      force: force,
    );
  }

  void _openedFromWidget(Uri? uri) {
    if (uri == null) return;
    AppNavigation.router.go(Routes.today);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
