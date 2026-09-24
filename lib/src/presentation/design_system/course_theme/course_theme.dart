import 'package:flutter/material.dart';

import '../../../domain/progress/student_progress.dart';
import '../brand/brand_colors.dart';

@immutable
final class DvxCourseThemeData {
  const DvxCourseThemeData({
    required this.id,
    required this.background,
    required this.foreground,
    required this.decorativePrimary,
    required this.decorativeSecondary,
    required this.reward,
    required this.reduceDecoration,
  });

  final String id;
  final Color background;
  final Color foreground;
  final Color decorativePrimary;
  final Color decorativeSecondary;
  final Color reward;
  final bool reduceDecoration;
}

abstract interface class DvxCourseTheme {
  String get id;

  DvxCourseThemeData resolve(AppThemePreference appTheme);
}

final class SpaceCourseTheme implements DvxCourseTheme {
  const SpaceCourseTheme();

  static const spaceNavy = Color(0xFF142B4A);
  static const cosmicPurple = Color(0xFF6657A8);
  static const star = Color(0xFFF5C451);

  @override
  String get id => 'space';

  @override
  DvxCourseThemeData resolve(AppThemePreference appTheme) => switch (appTheme) {
    AppThemePreference.standard => const DvxCourseThemeData(
      id: 'space',
      background: Color(0xFFE8F2F5),
      foreground: Color(0xFF172124),
      decorativePrimary: Color(0xFFCCDCE8),
      decorativeSecondary: cosmicPurple,
      reward: BrandColors.uspYellow,
      reduceDecoration: false,
    ),
    AppThemePreference.dark => const DvxCourseThemeData(
      id: 'space',
      background: Color(0xFF07111F),
      foreground: Color(0xFFF4F7FA),
      decorativePrimary: spaceNavy,
      decorativeSecondary: cosmicPurple,
      reward: star,
      reduceDecoration: false,
    ),
    AppThemePreference.highContrast => const DvxCourseThemeData(
      id: 'space',
      background: Color(0xFF000000),
      foreground: Color(0xFFFFFFFF),
      decorativePrimary: Color(0xFF000000),
      decorativeSecondary: Color(0xFF00D9F5),
      reward: Color(0xFFFFD000),
      reduceDecoration: true,
    ),
  };
}

final class NeutralCourseTheme implements DvxCourseTheme {
  const NeutralCourseTheme();

  @override
  String get id => 'default';

  @override
  DvxCourseThemeData resolve(AppThemePreference appTheme) => switch (appTheme) {
    AppThemePreference.standard => const DvxCourseThemeData(
      id: 'default',
      background: Color(0xFFF4F8FA),
      foreground: Color(0xFF172124),
      decorativePrimary: Color(0xFFF4F8FA),
      decorativeSecondary: BrandColors.uspBlue,
      reward: BrandColors.uspYellow,
      reduceDecoration: true,
    ),
    AppThemePreference.dark => const DvxCourseThemeData(
      id: 'default',
      background: Color(0xFF07111F),
      foreground: Color(0xFFF4F7FA),
      decorativePrimary: Color(0xFF07111F),
      decorativeSecondary: BrandColors.uspLightBlue,
      reward: BrandColors.uspYellow,
      reduceDecoration: true,
    ),
    AppThemePreference.highContrast => const DvxCourseThemeData(
      id: 'default',
      background: Color(0xFF000000),
      foreground: Color(0xFFFFFFFF),
      decorativePrimary: Color(0xFF000000),
      decorativeSecondary: Color(0xFF00D9F5),
      reward: Color(0xFFFFD000),
      reduceDecoration: true,
    ),
  };
}

abstract final class DvxCourseThemes {
  static const _space = SpaceCourseTheme();
  static const _neutral = NeutralCourseTheme();

  static DvxCourseTheme resolve(String id) => switch (id) {
    'space' => _space,
    _ => _neutral,
  };
}
