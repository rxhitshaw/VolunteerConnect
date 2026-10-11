import 'package:flutter/material.dart';

/// App-wide theme configuration for VolunteerConnect.
/// Adheres to Material 3 styling with a forest-green and warm-white palette.
class AppTheme {
  // Brand colors
  static const Color forestGreenDark = Color(0xFF1B4332);
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color forestGreenLight = Color(0xFF40916C);
  static const Color mintAccent = Color(0xFF74C69D);
  static const Color paleGreen = Color(0xFFD8F3DC);
  static const Color warmWhite = Color(0xFFFBFBF8);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1A1C19);
  static const Color textMuted = Color(0xFF5F6368);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: forestGreen,
      primary: forestGreen,
      onPrimary: Colors.white,
      primaryContainer: paleGreen,
      onPrimaryContainer: forestGreenDark,
      secondary: forestGreenLight,
      surface: warmWhite,
      onSurface: textDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: warmWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: warmWhite,
        foregroundColor: forestGreenDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: forestGreenDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 1.5,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withAlpha(12), width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: paleGreen,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: forestGreenDark,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestGreen,
          side: const BorderSide(color: forestGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
