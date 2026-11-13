import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../database/database.dart';
import '../navigation/app_navigation.dart';
import '../navigation/routes.dart';
import '../riverpods/backdrop_poster_provider.dart';
import '../riverpods/scene_providers.dart';
import '../riverpods/today_quote_of_the_day_provider.dart';
import '../service_locator/init_service_locators.dart';
import '../services/drift_quote_service.dart';
import '../services/home_widget_store.dart';
import '../services/quote_widget_service.dart';
import '../services/saved_widget_service.dart';
import '../services/scene_widget_service.dart';
import '../services/widget_analytics.dart';

/// Connects the app to its home-screen widgets (Quote of the Day, From your
/// saved, Scene of the Day):
/// - whenever today's quote, the day's scene (and poster) or the saved
///   quotes change, the matching widget's data is saved and it redraws;
/// - at app start, and when the app goes to the background, everything is
///   saved again, so the widgets catch up with anything the app loaded
///   meanwhile (and From your saved with the new day);
/// - a tap on a widget opens the app where it belongs (Saved for From your
///   saved, Today for the others) and is logged with the widget's kind;
/// - widget placements and removals since the last run are logged.
///
/// Sits in MaterialApp.builder next to MaintenanceGate. Does nothing on
/// platforms without widgets.
class QuoteWidgetBridge extends ConsumerStatefulWidget {
  final Widget child;

  const QuoteWidgetBridge({super.key, required this.child});

  @override
  ConsumerState<QuoteWidgetBridge> createState() => _QuoteWidgetBridgeState();
}

class _QuoteWidgetBridgeState extends ConsumerState<QuoteWidgetBridge> {
  AppLifecycleListener? _lifecycle;
  StreamSubscription<Uri?>? _clicks;
  StreamSubscription<List<Quote>>? _saved;
  List<SavedWidgetQuote>? _savedQuotes;

  @override
  void initState() {
    super.initState();
    if (!HomeWidgetStore.supported) return;
    _lifecycle = AppLifecycleListener(onHide: () => _syncAll(force: true));
    ref.listenManual(fetchTodayQuoteOfTheDayProvider, (_, next) {
      if (next.hasValue) _syncQuote();
    }, fireImmediately: true);
    ref.listenManual(sceneOfTheDayProvider, (_, next) {
      if (!next.isLoading) {
        _syncQuote();
        _syncScene();
      }
    }, fireImmediately: true);
    ref.listenManual(fallbackPosterProvider, (_, next) {
      if (!next.isLoading) _syncScene();
    }, fireImmediately: true);
    if (getIt.isRegistered<AppDatabase>()) {
      // A Drift query stream: emits now and on every save or unsave.
      _saved = DriftQuoteService.watchAllFavoriteQuotes(const []).listen((
        rows,
      ) {
        _savedQuotes = rows.map(SavedWidgetQuote.fromDrift).toList();
        _syncSaved();
      }, onError: (Object _) {});
    }
    HomeWidget.initiallyLaunchedFromHomeWidget().then(
      _openedFromWidget,
      onError: (Object _) {},
    );
    _clicks = HomeWidget.widgetClicked.listen(
      _openedFromWidget,
      onError: (Object _) {},
    );
    unawaited(WidgetAnalytics.flushPlacements());
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _clicks?.cancel();
    _saved?.cancel();
    super.dispose();
  }

  void _syncAll({bool force = false}) {
    _syncQuote(force: force);
    _syncScene(force: force);
    _syncSaved(force: force);
  }

  void _syncQuote({bool force = false}) {
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

  void _syncScene({bool force = false}) {
    // No scene (yet): keep whatever the widget showed last.
    final scene = ref.read(sceneOfTheDayProvider).value;
    if (scene == null) return;
    final fallback = ref.read(fallbackPosterProvider);
    final own = scene.sceneQuote.posterUrl;
    // Only wait for the fallback when it is needed.
    if ((own == null || own.isEmpty) && fallback.isLoading) return;
    SceneWidgetService.instance.update(
      scene: scene,
      fallbackPosterUrl: fallback.value,
      force: force,
    );
  }

  void _syncSaved({bool force = false}) {
    final saved = _savedQuotes;
    if (saved == null) return;
    SavedWidgetService.instance.update(saved, force: force);
  }

  void _openedFromWidget(Uri? uri) {
    if (uri == null) return;
    final kind = widgetKindOf(uri);
    WidgetAnalytics.opened(kind);
    AppNavigation.router.go(
      kind == QuotelyWidgetKind.saved ? Routes.saved : Routes.today,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The widget a tap URL came from: its `kind` query, else its path
/// (`/saved`), else Quote of the Day (whose URL had no kind before).
@visibleForTesting
QuotelyWidgetKind widgetKindOf(Uri uri) {
  final byQuery = QuotelyWidgetKind.fromId(uri.queryParameters['kind']);
  if (byQuery != null) return byQuery;
  if (uri.path == Routes.saved) return QuotelyWidgetKind.saved;
  return QuotelyWidgetKind.qotd;
}
