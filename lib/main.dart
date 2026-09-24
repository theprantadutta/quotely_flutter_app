import 'dart:io';
import 'dart:ui' show FlutterView;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';

import 'firebase_options.dart';
import 'navigation/app_navigation.dart';
import 'notifications/push_notification.dart';
import 'service_locator/init_service_locators.dart';
import 'theme/app_theme.dart';

Talker? talker;

void main() async {
  talker = TalkerFlutter.init(
    settings: TalkerSettings(
      // Only log in debug builds — keep release builds quiet and a touch faster.
      enabled: kDebugMode,
      colors: {
        // TalkerLogType.debug.key: AnsiPen()..magenta(),
        // TalkerLogType.verbose.key: AnsiPen()..magenta(),
      },
    ),
  );
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Edge-to-edge: content draws under the (transparent) status and navigation
  // bars, with SafeArea on each screen handling the inset padding. The native
  // opt-in lives in MainActivity; this is the Flutter-side half, and it keeps
  // us off SystemUiMode.manual, which routes through the deprecated
  // setStatusBarColor path that Play Console also flags.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  // Phones are portrait-only; tablets/iPads may rotate freely. No BuildContext
  // exists yet, so read the device class straight from the engine view.
  await _lockOrientationForDeviceClass(widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = (errorDetails) {
    // Crashlytics replaces the default handler; keep errors visible in the
    // console while developing.
    if (kDebugMode) FlutterError.presentError(errorDetails);
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  PushNotifications.init();
  await dotenv.load();
  initServiceLocator();
  // Read (and migrate) appearance before the first frame so the app never
  // flashes in the wrong theme or accent.
  Appearance.bootstrap = await AppearanceSettings.load(
    await SharedPreferences.getInstance(),
  );
  runApp(
    ProviderScope(
      observers: [TalkerRiverpodObserver(talker: talker!)],
      child: QuotelyApp(),
    ),
  );
}

/// Portrait-locks phones and frees tablets (shortest side >= 600dp), matching
/// `isTablet()` in constants/responsive.dart. On the rare Android device where
/// the view size isn't known yet at startup, default to portrait and re-check
/// after the first frame — worst case a tablet starts portrait and unlocks a
/// frame later.
Future<void> _lockOrientationForDeviceClass(WidgetsBinding binding) async {
  Future<void> apply(FlutterView view) {
    final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
    return SystemChrome.setPreferredOrientations(
      shortestSide >= 600
          ? DeviceOrientation.values
          : [DeviceOrientation.portraitUp],
    );
  }

  final view = binding.platformDispatcher.views.first;
  if (view.physicalSize.isEmpty) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    binding.addPostFrameCallback((_) {
      apply(binding.platformDispatcher.views.first);
    });
    return;
  }
  await apply(view);
}

class QuotelyApp extends ConsumerStatefulWidget {
  const QuotelyApp({super.key});

  @override
  ConsumerState<QuotelyApp> createState() => _QuotelyAppState();
}

class _QuotelyAppState extends ConsumerState<QuotelyApp> {
  Future<void> checkForAppUpdate() async {
    // In-app updates go through the Play Store, so they're Android-only.
    if (!Platform.isAndroid) return;
    if (!mounted) return;

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Flexible: downloads in the background while the app stays usable,
        // then prompts for the restart that installs it.
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('Something went wrong during the update check: $e');
    }
  }

  Future<void> setOptimalDisplayMode() async {
    // flutter_displaymode only has an Android implementation; iOS manages
    // refresh rate (ProMotion) automatically.
    if (!Platform.isAndroid) return;

    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution =
        supported
            .where(
              (DisplayMode m) =>
                  m.width == active.width && m.height == active.height,
            )
            .toList()
          ..sort(
            (DisplayMode a, DisplayMode b) =>
                b.refreshRate.compareTo(a.refreshRate),
          );

    await FlutterDisplayMode.setPreferredMode(
      sameResolution.isNotEmpty ? sameResolution.first : active,
    );
  }

  @override
  void initState() {
    super.initState();
    setOptimalDisplayMode();
    WidgetsBinding.instance.addPostFrameCallback((_) => checkForAppUpdate());
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);
    return MaterialApp.router(
      title: 'Quotely',
      routerConfig: AppNavigation.router,
      // System text size is honoured but clamped so the thread layout (fixed
      // 42px buttons, 34px avatars) never breaks at extreme settings.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.4,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: quotelyOverlayStyle(context.q),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      // Two sets of delegates on purpose. The first three satisfy
      // package:flutter/material.dart, which this app is written against; the
      // spread satisfies material_ui's own MaterialLocalizations type, which is
      // a DIFFERENT Dart type that flutter_localizations cannot provide.
      // go_router has migrated to material_ui, so without the spread its
      // widgets throw "No MaterialLocalizations found" at runtime - and the
      // crash surfaces far from the cause.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...material_ui.GlobalMaterialLocalizations.delegates,
      ],
      theme: buildQuotelyTheme(Brightness.light, appearance),
      darkTheme: buildQuotelyTheme(Brightness.dark, appearance),
      themeMode: appearance.themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
