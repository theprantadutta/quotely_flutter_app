import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';

import 'constants/selectors.dart';
import 'constants/shared_preference_keys.dart';
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
  await PushNotifications.init();
  initServiceLocator();
  await dotenv.load();
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
  bool _isBiometricEnabled = false;
  bool _isGridView = true;
  SharedPreferences? _sharedPreferences;
  final analytics = getIt.get<FirebaseAnalytics>();

  /// This is needed for components that may have a different theme data
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  FlexScheme get flexScheme => _flexScheme;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isGridView => _isGridView;

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
      _sharedPreferences?.setBool(kIsDarkModeKey, themeMode == ThemeMode.dark);
    });
    // Added for Firebase Analytics
    analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme_mode': themeMode.name},
    );
  }

  void initializeSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    final isGridView = _sharedPreferences?.getBool(kIsGridViewKey);
    if (isGridView != null) {
      setState(() => _isGridView = isGridView);
    }
    final isDarkMode = _sharedPreferences?.getBool(kIsDarkModeKey);
    if (isDarkMode != null) {
      setState(
        () => _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light,
      );
    }
    final flexScheme = _sharedPreferences?.getString(kFlexSchemeKey);
    if (flexScheme != null) {
      setState(() => _flexScheme = FlexScheme.values.byName(flexScheme));
    }
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

  @override
  void initState() {
    super.initState();
    setOptimalDisplayMode();
    initializeSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quotely',
      routerConfig: AppNavigation.router,
      theme: FlexThemeData.light(
        scheme: _flexScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.firaCode().fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: _flexScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.firaCode().fontFamily,
      ).copyWith(
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
