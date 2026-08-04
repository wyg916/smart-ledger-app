import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class LedgerPalette {
  static const cream = Color(0xFFFFF8E8);
  static const paper = Color(0xFFFFFDF8);
  static const ink = Color(0xFF3C332E);
  static const mutedInk = Color(0xFF766A64);
  static const coral = Color(0xFFE97867);
  static const coralSoft = Color(0xFFFFE1D9);
  static const mint = Color(0xFF56B6A3);
  static const mintSoft = Color(0xFFDDF3EC);
  static const honey = Color(0xFFF4BF4F);
  static const honeySoft = Color(0xFFFFEDB8);
  static const skySoft = Color(0xFFDDECF8);
}

ThemeData buildLedgerTheme() {
  const scheme = ColorScheme.light(
    primary: LedgerPalette.coral,
    onPrimary: Colors.white,
    primaryContainer: LedgerPalette.coralSoft,
    onPrimaryContainer: LedgerPalette.ink,
    secondary: LedgerPalette.mint,
    onSecondary: Colors.white,
    secondaryContainer: LedgerPalette.mintSoft,
    onSecondaryContainer: LedgerPalette.ink,
    tertiary: LedgerPalette.honey,
    onTertiary: LedgerPalette.ink,
    tertiaryContainer: LedgerPalette.honeySoft,
    onTertiaryContainer: LedgerPalette.ink,
    surface: LedgerPalette.paper,
    onSurface: LedgerPalette.ink,
    outline: Color(0xFFD8CAC0),
    outlineVariant: Color(0xFFEDE1D8),
    error: Color(0xFFBA4B4B),
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: LedgerPalette.cream,
    textTheme: base.textTheme.apply(
      bodyColor: LedgerPalette.ink,
      displayColor: LedgerPalette.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: LedgerPalette.ink,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: LedgerPalette.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: LedgerPalette.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: Color(0xFFF0E3D9)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: LedgerPalette.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFEADCD1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: LedgerPalette.coral, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LedgerPalette.coral,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: StadiumBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFEDE1D8)),
  );
}
