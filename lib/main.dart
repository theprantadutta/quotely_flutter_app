import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';

import 'constants/selectors.dart';
import 'constants/shared_preference_keys.dart';
import 'firebase_options.dart';
import 'navigation/app_navigation.dart';
import 'notifications/push_notification.dart';
import 'service_locator/init_service_locators.dart';

Talker? talker;

void main() async {
  talker = TalkerFlutter.init(
    settings: TalkerSettings(
      enabled: true,
      colors: {
        TalkerLogType.debug.key: AnsiPen()..magenta(),
        TalkerLogType.verbose.key: AnsiPen()..magenta(),
      },
    ),
  );
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = (errorDetails) {
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
  runApp(
    ProviderScope(
      observers: [
        TalkerRiverpodObserver(
          talker: talker!,
        ),
      ],
      child: QuotelyApp(),
    ),
  );
}

class QuotelyApp extends StatefulWidget {
  const QuotelyApp({super.key});

  @override
  State<QuotelyApp> createState() => _QuotelyAppState();

  //https://gist.github.com/ben-xx/10000ed3bf44e0143cf0fe7ac5648254
  // ignore: library_private_types_in_public_api
  static _QuotelyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_QuotelyAppState>()!;
}

class _QuotelyAppState extends State<QuotelyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  FlexScheme _flexScheme = kDefaultFlexTheme;
  ThemeMode get themeMode => _themeMode;
  bool _isBiometricEnabled = false;
  bool _isGridView = true;
  SharedPreferences? _sharedPreferences;
  String _fontFamily = 'Fira Code';
  final analytics = getIt.get<FirebaseAnalytics>();

  /// This is needed for components that may have a different theme data
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  FlexScheme get flexScheme => _flexScheme;
  String get fontFamily => _fontFamily;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isGridView => _isGridView;

  Future<void> checkForMaintenanceAndAppUpdate() async {
    debugPrint('Running checkForMaintenanceAndAppUpdate...');

    // A check to ensure the widget is still mounted before showing dialogs.
    if (!mounted) return;

    try {
      // --- Step 1: Check for Maintenance (Keeping your existing logic) ---
      // We still check for maintenance first - this is a great practice.
      // final appUpdateInfo = await AppInfoService().getAppUpdateInfo();
      // final maintenanceBreak = appUpdateInfo.maintenanceBreak;
      // debugPrint('Maintenance Break: $maintenanceBreak');

      // if (maintenanceBreak && mounted) {
      //   debugPrint('Maintenance Break is active, showing dialog...');
      //   await AppService.showMaintenanceDialog(context);
      //   return; // Stop further execution if in maintenance
      // }

      // --- Step 2: Check for an App Update using the in_app_update package ---
      // This talks directly to the Google Play Store.
      debugPrint("Checking for update via in_app_update package...");
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      // If an update is available...
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint("Update available. Starting flexible update flow.");

        // Start a user-friendly flexible update.
        // This downloads the update in the background while the user can still use the app.
        await InAppUpdate.startFlexibleUpdate();

        // Once the download is complete, this line will trigger a snackbar
        // prompting the user to restart the app to complete the installation.
        await InAppUpdate.completeFlexibleUpdate();

        debugPrint("Flexible update flow completed.");
      } else {
        debugPrint("No update available.");
      }

      // Your old code for manual version comparison is no longer needed for the update check.
      // The `in_app_update` package handles this automatically.
    } catch (e) {
      debugPrint('Something went wrong during the check: $e');
      // You can optionally show a non-intrusive error message here if needed.
    }
  }

  void changeFontFamily(String newFontFamily) {
    setState(() {
      _fontFamily = newFontFamily;
      _sharedPreferences?.setString(kFontFamilyKey, newFontFamily);
    });
    analytics.logEvent(
      name: 'font_family_changed',
      parameters: {'font_family': newFontFamily},
    );
  }

  void toggleGridViewEnabled() {
    setState(() {
      _isGridView = !_isGridView;
      _sharedPreferences?.setBool(kIsGridViewKey, _isGridView);
    });
    // Added for Firebase Analytics
    analytics.logEvent(
      name: 'view_mode_toggled',
      parameters: {'is_grid_view': _isGridView ? 'true' : 'false'},
    );
  }

  void changeBiometricEnabledEnabled(bool isBiometricEnabled) {
    setState(() {
      _isBiometricEnabled = isBiometricEnabled;
      _sharedPreferences?.setBool(kBiometricKey, isBiometricEnabled);
    });
    // Added for Firebase Analytics
    analytics.logEvent(
      name: 'biometric_toggle_changed',
      parameters: {
        'is_biometric_enabled': isBiometricEnabled ? 'true' : 'false'
      },
    );
  }

  void changeFlexScheme(FlexScheme flexScheme) {
    setState(() {
      _flexScheme = flexScheme;
      _sharedPreferences?.setString(kFlexSchemeKey, flexScheme.name);
    });
    // Added for Firebase Analytics
    analytics.logEvent(
      name: 'color_scheme_changed',
      parameters: {'flex_scheme': flexScheme.name},
    );
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
      _sharedPreferences?.setString(kThemeModeKey, themeMode.name);
    });
    // Added for Firebase Analytics
    analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme_mode': themeMode.name},
    );
  }

  void initializeSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    // --- load the saved font family ---
    final savedFont = _sharedPreferences?.getString(kFontFamilyKey);
    if (savedFont != null) {
      setState(() => _fontFamily = savedFont);
    }

    // Grid View
    final isGridView = _sharedPreferences?.getBool(kIsGridViewKey);
    if (isGridView != null) {
      setState(() => _isGridView = isGridView);
    }

    // Theme Mode (Light/System/Dark)
    final themeModeName = _sharedPreferences?.getString(kThemeModeKey);
    if (themeModeName != null) {
      final themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeModeName,
        orElse: () =>
            ThemeMode.light, // Default to light if saved value is invalid
      );
      setState(() => _themeMode = themeMode);
    }

    // Color Scheme
    final flexSchemeName = _sharedPreferences?.getString(kFlexSchemeKey);
    if (flexSchemeName != null) {
      final flexScheme = FlexScheme.values.firstWhere(
        (e) => e.name == flexSchemeName,
        orElse: () => kDefaultFlexTheme, // Use your default theme
      );
      setState(() => _flexScheme = flexScheme);
    }

    // Biometric
    final isFingerPrintEnabled = _sharedPreferences?.getBool(kBiometricKey);
    if (isFingerPrintEnabled != null) {
      setState(() => _isBiometricEnabled = isFingerPrintEnabled);
    }
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution = supported
        .where((DisplayMode m) =>
            m.width == active.width && m.height == active.height)
        .toList()
      ..sort((DisplayMode a, DisplayMode b) =>
          b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode =
        sameResolution.isNotEmpty ? sameResolution.first : active;

    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }

  /// Resets all appearance and layout settings to their original default values.
  Future<void> resetAllSettings() async {
    // 1. Update the state to reflect the default values immediately.
    setState(() {
      _themeMode = ThemeMode.light;
      _flexScheme = kDefaultFlexTheme; // Your defined default theme
      _fontFamily = 'Fira Code';
      _isGridView = true;
      _isBiometricEnabled = false; // Assuming false is the default
    });

    // 2. Log a single analytics event for this action.
    analytics.logEvent(name: 'settings_reset_to_default');

    // 3. Remove the saved preferences so the app uses defaults on next launch.
    // We do this after updating the state for a snappy UI response.
    await _sharedPreferences?.remove(kThemeModeKey);
    await _sharedPreferences?.remove(kFlexSchemeKey);
    await _sharedPreferences?.remove(kFontFamilyKey);
    await _sharedPreferences?.remove(kIsGridViewKey);
    await _sharedPreferences?.remove(kBiometricKey);
  }

  @override
  void initState() {
    super.initState();
    setOptimalDisplayMode();
    initializeSharedPreferences();
    // Use addPostFrameCallback to ensure context is available for the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForMaintenanceAndAppUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quotely',
      routerConfig: AppNavigation.router,
      theme: FlexThemeData.light(
        scheme: _flexScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.getFont(_fontFamily).fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: _flexScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.getFont(_fontFamily).fontFamily,
      ).copyWith(
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
