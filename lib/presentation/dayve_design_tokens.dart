import 'package:flutter/material.dart';

abstract final class DayveColors {
  static const background = Color(0xfff8f6ff);
  static const backgroundSoft = Color(0xfff3f0ff);
  static const primaryPurple = Color(0xff7566e8);
  static const lightPurple = Color(0xffc8beff);
  static const progressStart = Color(0xff9c8cff);
  static const progressEnd = Color(0xff87c8ff);
  static const primaryText = Color(0xff181721);
  static const secondaryText = Color(0xff777483);
  static const card = Color(0xf0ffffff);
  static const border = Color(0xffeae6fa);
}

abstract final class DayveRadii {
  static const large = 30.0;
  static const medium = 22.0;
  static const button = 20.0;
  static const progress = 999.0;
}

abstract final class DayveSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

ThemeData buildDayveTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: DayveColors.primaryPurple,
    brightness: Brightness.light,
    surface: Colors.white,
  ).copyWith(
    primary: DayveColors.primaryPurple,
    secondary: DayveColors.lightPurple,
    onSurface: DayveColors.primaryText,
    outline: DayveColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DayveColors.background,
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: DayveColors.primaryText,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        color: DayveColors.primaryText,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(
        color: DayveColors.primaryText,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: DayveColors.primaryText),
      bodySmall: TextStyle(color: DayveColors.secondaryText),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DayveRadii.button),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 60,
      backgroundColor: Colors.white,
      indicatorColor: DayveColors.backgroundSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? DayveColors.primaryPurple
              : DayveColors.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
