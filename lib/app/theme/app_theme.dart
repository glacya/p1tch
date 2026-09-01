import 'package:flutter/material.dart';
import 'package:p2tch/app/constants/color_constants.dart';

/// Builds a [ThemeData] from [palette] so default widgets (Scaffold,
/// AppBar, Text, ElevatedButton, TextButton, Icon) pick up our own colors
/// instead of Flutter's auto-generated Material scheme. Fields with no
/// single ThemeData slot (aura states, ripple, tile surface) are read
/// directly from the [CategoryPalette] by the widgets that need them.
ThemeData themeFromPalette(CategoryPalette palette) {
  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: palette.button,
      onPrimary: palette.buttonText,
      surface: palette.surface,
      onSurface: palette.text,
    ),
  );

  return baseTheme.copyWith(
    scaffoldBackgroundColor: palette.background,
    appBarTheme: baseTheme.appBarTheme.copyWith(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
    ),
    textTheme: baseTheme.textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.button,
        foregroundColor: palette.buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.button),
    ),
    iconTheme: baseTheme.iconTheme.copyWith(color: palette.text),
    dividerColor: palette.border,
  );
}

abstract class AppTheme {
  AppTheme._();

  /// The app-wide default theme, used by screens that aren't tied to a
  /// specific category (Home, Level Category, Settings) - the "departure"
  /// palette per se, but referred to as "core" here since its role is to be
  /// the app's baseline look, not literally the departure category's own.
  static final core = themeFromPalette(CategoryColors.palettes['departure']!);
}
