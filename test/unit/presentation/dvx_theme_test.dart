import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:digitavox_criancas/src/presentation/design_system/app_theme/dvx_app_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/brand/brand_colors.dart';
import 'package:digitavox_criancas/src/presentation/design_system/course_theme/course_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/tokens/dvx_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves the Standard semantic palette', () {
    final theme = DvxAppTheme.resolve(AppThemePreference.standard);
    final tokens = theme.extension<DvxThemeTokens>()!;

    expect(theme.scaffoldBackgroundColor, const Color(0xFFF4F8FA));
    expect(theme.colorScheme.primary, const Color(0xFF087A91));
    expect(theme.colorScheme.secondary, BrandColors.uspBlue);
    expect(tokens.accent, BrandColors.uspYellow);
    expect(tokens.highContrast, isFalse);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Open Sans');
  });

  test('resolves the Dark semantic palette', () {
    final theme = DvxAppTheme.resolve(AppThemePreference.dark);
    final tokens = theme.extension<DvxThemeTokens>()!;

    expect(theme.scaffoldBackgroundColor, const Color(0xFF07111F));
    expect(theme.colorScheme.primary, BrandColors.uspLightBlue);
    expect(tokens.surfaceVariant, const Color(0xFF172A3D));
    expect(tokens.focus, const Color(0xFFFFD166));
  });

  test('resolves High Contrast with stronger focus and black background', () {
    final theme = DvxAppTheme.resolve(AppThemePreference.highContrast);
    final tokens = theme.extension<DvxThemeTokens>()!;

    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.colorScheme.primary, const Color(0xFF00D9F5));
    expect(tokens.focus, const Color(0xFFFFFF00));
    expect(tokens.focusWidth, 4);
    expect(tokens.highContrast, isTrue);
  });

  test('composes the space course identity with each app theme', () {
    const space = SpaceCourseTheme();

    final standard = space.resolve(AppThemePreference.standard);
    final dark = space.resolve(AppThemePreference.dark);
    final highContrast = space.resolve(AppThemePreference.highContrast);

    expect(DvxCourseThemes.resolve('space'), isA<SpaceCourseTheme>());
    expect(DvxCourseThemes.resolve('forest'), isA<NeutralCourseTheme>());
    expect(standard.id, 'space');
    expect(standard.background, isNot(dark.background));
    expect(dark.decorativeSecondary, SpaceCourseTheme.cosmicPurple);
    expect(highContrast.background, Colors.black);
    expect(highContrast.reduceDecoration, isTrue);
  });
}
