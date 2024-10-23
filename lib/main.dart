import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/selectors.dart';
import 'constants/shared_preference_keys.dart';
import 'navigation/app_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  //https://gist.github.com/ben-xx/10000ed3bf44e0143cf0fe7ac5648254
  // ignore: library_private_types_in_public_api
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  FlexScheme _flexScheme = kDefaultFlexTheme;
  bool _isBiometricEnabled = false;
  SharedPreferences? _sharedPreferences;

  /// This is needed for components that may have a different theme data
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  FlexScheme get flexScheme => _flexScheme;
  bool get isBiometricEnabled => _isBiometricEnabled;

  void changeBiometricEnabledEnabled(bool isisBiometricEnabled) {
    setState(() {
      _isBiometricEnabled = isisBiometricEnabled;
      _sharedPreferences?.setBool(kBiometricKey, isisBiometricEnabled);
    });
  }

  void changeFlexScheme(FlexScheme flexScheme) {
    setState(() {
      _flexScheme = flexScheme;
      _sharedPreferences?.setString(kFlexSchemeKey, flexScheme.name);
    });
  }

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
      _sharedPreferences?.setBool(kIsDarkModeKey, themeMode == ThemeMode.dark);
    });
  }

  void intializeSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    final isDarkMode = _sharedPreferences?.getBool(kIsDarkModeKey);
    if (isDarkMode != null) {
      setState(
          () => _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light);
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

  @override
  void initState() {
    super.initState();
    intializeSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quotely',
      routerConfig: AppNavigation.router,
      theme: FlexThemeData.light(
        scheme: _flexScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.nunito().fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: _flexScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.nunito().fontFamily,
      ).copyWith(
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
    );
  }
}
