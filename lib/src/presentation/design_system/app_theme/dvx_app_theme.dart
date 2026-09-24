import 'package:flutter/material.dart';

import '../../../domain/progress/student_progress.dart';
import '../brand/brand_colors.dart';
import '../tokens/dvx_tokens.dart';

abstract final class DvxAppTheme {
  static ThemeData resolve(AppThemePreference preference) =>
      switch (preference) {
        AppThemePreference.standard => _build(
          brightness: Brightness.light,
          background: const Color(0xFFF4F8FA),
          surface: const Color(0xFFFFFFFF),
          surfaceVariant: const Color(0xFFE8F2F5),
          primary: const Color(0xFF087A91),
          secondary: BrandColors.uspBlue,
          accent: BrandColors.uspYellow,
          textPrimary: const Color(0xFF172124),
          textSecondary: const Color(0xFF526166),
          success: const Color(0xFF287A4D),
          error: const Color(0xFFB3261E),
          focus: const Color(0xFFE19A00),
        ),
        AppThemePreference.dark => _build(
          brightness: Brightness.dark,
          background: const Color(0xFF07111F),
          surface: const Color(0xFF101D2D),
          surfaceVariant: const Color(0xFF172A3D),
          primary: BrandColors.uspLightBlue,
          secondary: const Color(0xFF72D6E3),
          accent: BrandColors.uspYellow,
          textPrimary: const Color(0xFFF4F7FA),
          textSecondary: const Color(0xFFBBC8D4),
          success: const Color(0xFF5DD39E),
          error: const Color(0xFFFF8A80),
          focus: const Color(0xFFFFD166),
        ),
        AppThemePreference.highContrast => _build(
          brightness: Brightness.dark,
          background: const Color(0xFF000000),
          surface: const Color(0xFF000000),
          surfaceVariant: const Color(0xFF121212),
          primary: const Color(0xFF00D9F5),
          secondary: const Color(0xFF00D9F5),
          accent: const Color(0xFFFFD000),
          textPrimary: const Color(0xFFFFFFFF),
          textSecondary: const Color(0xFFFFFFFF),
          success: const Color(0xFF00FF66),
          error: const Color(0xFFFF5252),
          focus: const Color(0xFFFFFF00),
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
      outline: highContrast ? textPrimary : textSecondary,
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
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
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
        ),
      ],
    );
  }

  static Color _contrasting(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
