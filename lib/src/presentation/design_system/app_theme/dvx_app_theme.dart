import 'package:flutter/material.dart';

import '../../../domain/progress/student_progress.dart';
import '../tokens/dvx_tokens.dart';

abstract final class DvxAppTheme {
  static ThemeData resolve(AppThemePreference preference) =>
      switch (preference) {
        AppThemePreference.standard => _build(
          brightness: Brightness.light,
          background: const Color(0xFFFFF4F7),
          surface: const Color(0xFFF6D9E3),
          surfaceVariant: const Color(0xFFF6D9E3),
          primary: const Color(0xFF2B0B1E),
          secondary: const Color(0xFF00707F),
          accent: const Color(0xFFFFC42E),
          textPrimary: const Color(0xFF2B0B1E),
          textSecondary: const Color(0xFF2B0B1E),
          success: const Color(0xFF00707F),
          error: const Color(0xFFB34700),
          focus: const Color(0xFF2B0B1E),
          outline: const Color(0xFF2B0B1E),
        ),
        AppThemePreference.dark => _build(
          brightness: Brightness.dark,
          background: const Color(0xFF2B0B1E),
          surface: const Color(0xFF4A1634),
          surfaceVariant: const Color(0xFF4A1634),
          primary: const Color(0xFFFFC42E),
          secondary: const Color(0xFF3DF2FF),
          accent: const Color(0xFFFFC42E),
          textPrimary: const Color(0xFFFFF6EC),
          textSecondary: const Color(0xFFFFF6EC),
          success: const Color(0xFF3DF2FF),
          error: const Color(0xFFFF9F43),
          focus: const Color(0xFFFFC42E),
          outline: const Color(0xFFFFF6EC),
        ),
        AppThemePreference.highContrast => _build(
          brightness: Brightness.dark,
          background: const Color(0xFF000000),
          surface: const Color(0xFF000000),
          surfaceVariant: const Color(0xFF000000),
          primary: const Color(0xFFFFFF00),
          secondary: const Color(0xFFFFFF00),
          accent: const Color(0xFFFFFF00),
          textPrimary: const Color(0xFFFFFFFF),
          textSecondary: const Color(0xFFFFFFFF),
          success: const Color(0xFFFFFF00),
          error: const Color(0xFFFFFF00),
          focus: const Color(0xFFFFFF00),
          outline: const Color(0xFFFFFFFF),
          highContrast: true,
        ),
      };

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color primary,
    required Color secondary,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
    required Color success,
    required Color error,
    required Color focus,
    required Color outline,
    bool highContrast = false,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: _contrasting(primary),
      secondary: secondary,
      onSecondary: _contrasting(secondary),
      error: error,
      onError: _contrasting(error),
      surface: surface,
      onSurface: textPrimary,
      tertiary: accent,
      onTertiary: _contrasting(accent),
      outline: highContrast ? Colors.white : outline,
      outlineVariant: highContrast ? focus : surfaceVariant,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Open Sans',
    );
    final textTheme = base.textTheme
        .apply(bodyColor: textPrimary, displayColor: textPrimary)
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontFamily: 'Fredoka',
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: 'Fredoka',
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontFamily: 'Fredoka',
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: 'Fredoka',
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontFamily: 'Fredoka',
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
        );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DvxRadius.md),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DvxRadius.md),
      side: highContrast
          ? BorderSide(color: textPrimary, width: 2)
          : BorderSide.none,
    );
    final focusedSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: focus, width: highContrast ? 4 : 3);
      }
      return null;
    });
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: highContrast ? 0 : 2,
        shape: cardShape,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ).copyWith(side: focusedSide),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: const Size(48, 56),
              foregroundColor: primary,
              side: BorderSide(
                color: highContrast ? textPrimary : primary,
                width: highContrast ? 2 : 1.5,
              ),
              shape: buttonShape,
              textStyle: textTheme.labelLarge,
            ).copyWith(
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return BorderSide(color: focus, width: highContrast ? 4 : 3);
                }
                return BorderSide(
                  color: highContrast ? textPrimary : primary,
                  width: highContrast ? 2 : 1.5,
                );
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceVariant,
      ),
      focusColor: focus,
      extensions: <ThemeExtension<dynamic>>[
        DvxThemeTokens(
          accent: accent,
          success: success,
          focus: focus,
          textSecondary: textSecondary,
          surfaceVariant: surfaceVariant,
          focusWidth: highContrast ? 4 : 3,
          borderWidth: highContrast ? 2 : 1,
          highContrast: highContrast,
          outline: outline,
        ),
      ],
    );
  }

  static Color _contrasting(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
