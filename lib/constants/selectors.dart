import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kDefaultFlexTheme = FlexScheme.purpleM3;

SystemUiOverlayStyle getDefaultSystemUiStyle(bool isDarkTheme) {
  return SystemUiOverlayStyle(
    // Status bar color
    statusBarColor: Colors.transparent,
    // Status bar brightness (optional)
    statusBarIconBrightness: isDarkTheme
        ? Brightness.light
        : Brightness.dark, // For Android (dark icons)
    statusBarBrightness: isDarkTheme
        ? Brightness.dark
        : Brightness.light, // For iOS (dark icons)
  );
}
