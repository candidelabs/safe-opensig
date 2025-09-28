import 'package:flutter/material.dart';

class ThemeConfig {
  // COLORS
  static const Color primary = Color(0xFF00E078);
  static const Color primaryVariant = Color(0xFF006636);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);

  // DARK THEME COLORS
  static const Color darkPrimary = Color(0xFF00B460);
  static const Color darkPrimaryVariant = Color(0xFF006636);
  static const Color darkSecondary = Color(0xFF03DAC6);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnSecondary = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnError = Color(0xFF000000);

  // FONTS
  static const String fontFamily = 'Roboto';

  // TEXT STYLES
  static final TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      // letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      // letterSpacing: 0.25,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      // letterSpacing: 0.15,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      // letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      // letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontFamily: fontFamily,
      // letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontFamily: fontFamily,
      // letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontFamily: fontFamily,
      // letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      // letterSpacing: 1.25,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      // letterSpacing: 1.5,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      // letterSpacing: 1.5,
    ),
  );

  // BORDERS
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(4);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(8);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(12);
  static final BorderRadius borderRadiusXLarge = BorderRadius.circular(16);

  // SHADOWS
  static final List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  // SPACING
  static const double spacingXSmall = 4;
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;
  static const double spacingXXLarge = 48;

  // ICON SIZES
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 24;
  static const double iconSizeLarge = 32;
  static const double iconSizeXLarge = 48;

  // BUTTON STYLES
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: spacingLarge,
      vertical: spacingMedium,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusLarge,
    ),
  );

  static final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  static final ButtonStyle textButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: spacingLarge,
      vertical: spacingMedium,
    ),
  );

  static ElevatedButtonThemeData get elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return ThemeConfig.primaryVariant.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.pressed)) {
            return ThemeConfig.primary.withValues(alpha: 0.9);
          }
          if (states.contains(WidgetState.hovered)) {
            return ThemeConfig.primary.withValues(alpha: 0.9);
          }
          return ThemeConfig.primary;
        }),
        foregroundColor: WidgetStateProperty.all(ThemeConfig.onPrimary),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        )),
        elevation: WidgetStateProperty.resolveWith<double>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return 0;
            }
            if (states.contains(WidgetState.pressed)) {
              return 4;
            }
            if (states.contains(WidgetState.hovered)) {
              return 2;
            }
            if (states.contains(WidgetState.focused)) {
              return 2;
            }
            return 0.5;
          },
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return ThemeConfig.primaryVariant.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.pressed)) {
              return ThemeConfig.primaryVariant.withValues(alpha: 0.2);
            }
            if (states.contains(WidgetState.focused)) {
              return ThemeConfig.primaryVariant.withValues(alpha: 0.05);
            }
            return null;
          },
        ),
      ),
    );
  }

  static FloatingActionButtonThemeData get floatingActionButtonTheme {
    return FloatingActionButtonThemeData(
        backgroundColor: ThemeConfig.primary,
        foregroundColor: ThemeConfig.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 1,
        hoverColor: ThemeConfig.primaryVariant.withValues(alpha: 0.1),
        splashColor: ThemeConfig.primaryVariant.withValues(alpha: 0.25)
    );
  }

  static ElevatedButtonThemeData get darkElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return ThemeConfig.darkPrimaryVariant.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.pressed)) {
            return ThemeConfig.darkPrimary.withValues(alpha: 0.9);
          }
          if (states.contains(WidgetState.hovered)) {
            return ThemeConfig.darkPrimary.withValues(alpha: 0.9);
          }
          return ThemeConfig.darkPrimary;
        }),
        foregroundColor: WidgetStateProperty.all(ThemeConfig.darkOnPrimary),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        )),
        elevation: WidgetStateProperty.resolveWith<double>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return 0;
            }
            if (states.contains(WidgetState.pressed)) {
              return 6;
            }
            if (states.contains(WidgetState.hovered)) {
              return 4;
            }
            if (states.contains(WidgetState.focused)) {
              return 4;
            }
            return 2;
          },
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return ThemeConfig.darkPrimaryVariant.withValues(alpha: 0.1);
            }
            if (states.contains(WidgetState.pressed)) {
              return ThemeConfig.darkPrimaryVariant.withValues(alpha: 0.2);
            }
            if (states.contains(WidgetState.focused)) {
              return ThemeConfig.darkPrimaryVariant.withValues(alpha: 0.05);
            }
            return null;
          },
        ),
      ),
    );
  }

  static FloatingActionButtonThemeData get darkFloatingActionButtonTheme {
    return FloatingActionButtonThemeData(
      backgroundColor: ThemeConfig.darkPrimary,
      foregroundColor: ThemeConfig.darkOnPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      hoverColor: ThemeConfig.darkPrimaryVariant.withValues(alpha: 0.1),
      splashColor: ThemeConfig.darkPrimaryVariant.withValues(alpha: 0.25)
    );
  }

}