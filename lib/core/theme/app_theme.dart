import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Brand colours ────────────────────────────────────────────────────────
  static const deepGreen = Color(0xFF1D6F42);
  static const neonGreen = Color(0xFF39FF88);
  static const neonBlue = Color(0xFF33D1FF);
  static const lossRed = Color(0xFFFF4D67);
  static const warningAmber = Color(0xFFFFB347);

  // ── Light ────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const bg = Color(0xFFF4FBF6);
    const card = Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: deepGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: deepGreen,
      secondary: neonBlue,
      error: lossRed,
      surface: card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,

      // Global bouncing scroll
      scrollbarTheme: const ScrollbarThemeData(thumbVisibility: WidgetStatePropertyAll(false)),

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: Colors.white,
        indicatorColor: deepGreen.withValues(alpha: 0.12),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: deepGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: deepGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: deepGreen,
        inactiveTrackColor: deepGreen.withValues(alpha: 0.18),
        thumbColor: deepGreen,
        overlayColor: deepGreen.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),

      chipTheme: ChipThemeData(
        selectedColor: deepGreen,
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Color(0xFFDDDDDD)),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE8F5EC), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  // ── Dark ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const bg = Color(0xFF070E09);
    const surface = Color(0xFF0F1712);
    final scheme = ColorScheme.fromSeed(
      seedColor: neonGreen,
      brightness: Brightness.dark,
    ).copyWith(
      primary: neonGreen,
      secondary: neonBlue,
      error: lossRed,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,

      scrollbarTheme: const ScrollbarThemeData(thumbVisibility: WidgetStatePropertyAll(false)),

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: surface,
        indicatorColor: neonGreen.withValues(alpha: 0.15),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: const Color(0xFF070E09),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: neonGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: neonGreen,
        inactiveTrackColor: neonGreen.withValues(alpha: 0.18),
        thumbColor: neonGreen,
        overlayColor: neonGreen.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),

      chipTheme: ChipThemeData(
        selectedColor: neonGreen,
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
