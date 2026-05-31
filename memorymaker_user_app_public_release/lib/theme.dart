import 'package:flutter/material.dart';

class MmColors {
  static const ivory = Color(0xFFFFF8F1);
  static const blush = Color(0xFFF8E7E2);
  static const rose = Color(0xFFC77982);
  static const roseDark = Color(0xFF8E5660);
  static const ink = Color(0xFF34292C);
  static const muted = Color(0xFF7D6970);
  static const champagne = Color(0xFFEAD1B3);
  static const success = Color(0xFF3B7A57);
}

ThemeData buildMemoryMakerTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: MmColors.rose, brightness: Brightness.light, primary: MmColors.roseDark, secondary: MmColors.champagne, surface: Colors.white);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: MmColors.ivory,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: MmColors.ink, centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: MmColors.blush.withOpacity(.7))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: MmColors.blush.withOpacity(.9))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: MmColors.roseDark, width: 1.4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MmColors.roseDark,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: MmColors.blush.withOpacity(.8))),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: MmColors.blush,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? MmColors.roseDark : MmColors.muted)),
    ),
  );
}
