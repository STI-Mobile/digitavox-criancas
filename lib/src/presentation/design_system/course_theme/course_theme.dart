import 'package:flutter/material.dart';

import '../../../domain/progress/student_progress.dart';

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

  static const cosmicBlue = Color(0xFF3DF2FF);
  static const star = Color(0xFFFFC42E);

  @override
  String get id => 'space';

  @override
  DvxCourseThemeData resolve(AppThemePreference appTheme) => switch (appTheme) {
    AppThemePreference.standard => const DvxCourseThemeData(
      id: 'space',
      background: Color(0xFFFFF4F7),
      foreground: Color(0xFF2B0B1E),
      decorativePrimary: Color(0xFFF6D9E3),
      decorativeSecondary: Color(0xFF00707F),
      reward: Color(0xFFFFC42E),
      reduceDecoration: false,
    ),
    AppThemePreference.dark => const DvxCourseThemeData(
      id: 'space',
      background: Color(0xFF2B0B1E),
      foreground: Color(0xFFFFF6EC),
      decorativePrimary: Color(0xFF4A1634),
      decorativeSecondary: cosmicBlue,
      reward: star,
      reduceDecoration: false,
    ),
    AppThemePreference.highContrast => const DvxCourseThemeData(
      id: 'space',
      background: Color(0xFF000000),
      foreground: Color(0xFFFFFFFF),
      decorativePrimary: Color(0xFF000000),
      decorativeSecondary: Color(0xFFFFFF00),
      reward: Color(0xFFFFFF00),
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
      background: Color(0xFFFFF4F7),
      foreground: Color(0xFF2B0B1E),
      decorativePrimary: Color(0xFFF6D9E3),
      decorativeSecondary: Color(0xFF00707F),
      reward: Color(0xFFFFC42E),
      reduceDecoration: true,
    ),
    AppThemePreference.dark => const DvxCourseThemeData(
      id: 'default',
      background: Color(0xFF2B0B1E),
      foreground: Color(0xFFFFF6EC),
      decorativePrimary: Color(0xFF4A1634),
      decorativeSecondary: Color(0xFF3DF2FF),
      reward: Color(0xFFFFC42E),
      reduceDecoration: true,
    ),
    AppThemePreference.highContrast => const DvxCourseThemeData(
      id: 'default',
      background: Color(0xFF000000),
      foreground: Color(0xFFFFFFFF),
      decorativePrimary: Color(0xFF000000),
      decorativeSecondary: Color(0xFFFFFF00),
      reward: Color(0xFFFFFF00),
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
