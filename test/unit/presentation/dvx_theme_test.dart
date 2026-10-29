import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:digitavox_criancas/src/presentation/design_system/app_theme/dvx_app_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/course_theme/course_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/tokens/accessibility_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to Escuro and names the light theme Claro without changing its identifier', () {
    expect(const AppSettings().themePreference, AppThemePreference.dark);
    expect(AppThemePreference.standard.label, 'Claro');
    expect(AppThemePreference.parse('standard'), AppThemePreference.standard);
  });
  test('resolves the Claro identity palette', () {
    final theme = DvxAppTheme.resolve(AppThemePreference.standard);

    expect(theme.scaffoldBackgroundColor, const Color(0xFFFFF4F7));
    expect(theme.cardTheme.color, const Color(0xFFF6D9E3));
    expect(theme.colorScheme.primary, const Color(0xFF2B0B1E));
    expect(theme.colorScheme.error, const Color(0xFFB34700));
    expect(theme.colorScheme.tertiary, const Color(0xFFFFC42E));
    expect(theme.colorScheme.secondary, const Color(0xFF00707F));
    expect(theme.extension<DvxAccessibilityTokens>()!.highContrast, isFalse);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Open Sans');
    expect(theme.textTheme.titleMedium?.fontFamily, 'Fredoka');
    expect(theme.textTheme.headlineMedium?.fontFamily, 'Fredoka');
    expect(theme.textTheme.displayLarge?.fontFamily, 'Fredoka');
  });

  test('resolves the Escuro identity palette', () {
    final theme = DvxAppTheme.resolve(AppThemePreference.dark);

    expect(theme.scaffoldBackgroundColor, const Color(0xFF2B0B1E));
    expect(theme.cardTheme.color, const Color(0xFF4A1634));
    expect(theme.colorScheme.primary, const Color(0xFFFFC42E));
    expect(theme.colorScheme.onPrimary, Colors.black);
    expect(theme.colorScheme.onSurface, const Color(0xFFFFF6EC));
    expect(theme.colorScheme.error, const Color(0xFFFF9F43));
    expect(theme.colorScheme.outlineVariant, const Color(0xFF4A1634));
    expect(theme.colorScheme.secondary, const Color(0xFF3DF2FF));
    expect(theme.focusColor, const Color(0xFFFFC42E));

  });

  test('resolves High Contrast with stronger focus and black background', () {
    final theme = DvxAppTheme.resolve(AppThemePreference.highContrast);

    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.colorScheme.primary, const Color(0xFFFFFF00));
    expect(theme.colorScheme.onPrimary, Colors.black);
    expect(theme.colorScheme.onSurface, Colors.white);
    expect(theme.focusColor, const Color(0xFFFFFF00));
    expect(theme.extension<DvxAccessibilityTokens>()!.focusWidth, 4);
    expect(theme.extension<DvxAccessibilityTokens>()!.highContrast, isTrue);
  });

  test('composes the space course identity with each app theme', () {
    const space = SpaceCourseTheme();

    final standard = space.resolve(AppThemePreference.standard);
    final dark = space.resolve(AppThemePreference.dark);
    final highContrast = space.resolve(AppThemePreference.highContrast);

    expect(DvxCourseThemes.resolve('space'), isA<SpaceCourseTheme>());
    expect(DvxCourseThemes.resolve('forest'), isA<NeutralCourseTheme>());
    expect(standard.id, 'space');
    expect(standard.background, const Color(0xFFFFF4F7));
    expect(standard.foreground, const Color(0xFF2B0B1E));
    expect(standard.decorativePrimary, const Color(0xFFF6D9E3));
    expect(standard.decorativeSecondary, const Color(0xFF2B0B1E));
    expect(standard.reward, const Color(0xFFFFC42E));
    expect(standard.background, isNot(dark.background));
    expect(dark.background, const Color(0xFF2B0B1E));
    expect(dark.foreground, const Color(0xFFFFF6EC));
    expect(dark.decorativePrimary, const Color(0xFF4A1634));
    expect(dark.decorativeSecondary, const Color(0xFFFFC42E));
    expect(dark.reward, const Color(0xFFFFC42E));
    expect(highContrast.background, Colors.black);
    expect(highContrast.foreground, Colors.white);
    expect(highContrast.decorativeSecondary, const Color(0xFFFFFF00));
    expect(highContrast.reward, const Color(0xFFFFFF00));
    expect(highContrast.reduceDecoration, isTrue);
  });
}
