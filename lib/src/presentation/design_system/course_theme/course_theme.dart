import 'package:flutter/material.dart';

import '../../../domain/progress/student_progress.dart';

@immutable
final class DvxCourseSpacing {
  const DvxCourseSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  DvxCourseSpacing lerp(DvxCourseSpacing other, double t) => DvxCourseSpacing(
    xs: _lerp(xs, other.xs, t),
    sm: _lerp(sm, other.sm, t),
    md: _lerp(md, other.md, t),
    lg: _lerp(lg, other.lg, t),
    xl: _lerp(xl, other.xl, t),
  );
}

@immutable
final class DvxCourseRadius {
  const DvxCourseRadius({this.sm = 8, this.md = 16, this.lg = 24});

  final double sm;
  final double md;
  final double lg;

  DvxCourseRadius lerp(DvxCourseRadius other, double t) => DvxCourseRadius(
    sm: _lerp(sm, other.sm, t),
    md: _lerp(md, other.md, t),
    lg: _lerp(lg, other.lg, t),
  );
}

@immutable
final class DvxCourseThemeData extends ThemeExtension<DvxCourseThemeData> {
  const DvxCourseThemeData({
    required this.id,
    required this.background,
    required this.foreground,
    required this.decorativePrimary,
    required this.decorativeSecondary,
    required this.reward,
    required this.reduceDecoration,
    this.surface,
    this.primary,
    this.success,
    this.error,
    this.focus,
    this.outline,
    this.spacing = const DvxCourseSpacing(),
    this.radius = const DvxCourseRadius(),
  });

  final String id;
  final Color background;
  final Color foreground;
  final Color decorativePrimary;
  final Color decorativeSecondary;
  final Color reward;
  final bool reduceDecoration;
  final Color? surface;
  final Color? primary;
  final Color? success;
  final Color? error;
  final Color? focus;
  final Color? outline;
  final DvxCourseSpacing spacing;
  final DvxCourseRadius radius;

  Color get resolvedSurface => surface ?? decorativePrimary;
  Color get resolvedPrimary => primary ?? decorativeSecondary;
  Color get resolvedSuccess => success ?? decorativeSecondary;
  Color get resolvedError => error ?? foreground;
  Color get resolvedFocus => focus ?? decorativeSecondary;
  Color get resolvedOutline => outline ?? foreground;
  Color get onPrimary => _contrast(resolvedPrimary);
  Color get onSecondary => _contrast(decorativeSecondary);
  Color get onError => _contrast(resolvedError);
  Color get onReward => _contrast(reward);

  @override
  DvxCourseThemeData copyWith({
    String? id,
    Color? background,
    Color? foreground,
    Color? decorativePrimary,
    Color? decorativeSecondary,
    Color? reward,
    bool? reduceDecoration,
    Color? surface,
    Color? primary,
    Color? success,
    Color? error,
    Color? focus,
    Color? outline,
    DvxCourseSpacing? spacing,
    DvxCourseRadius? radius,
  }) => DvxCourseThemeData(
    id: id ?? this.id,
    background: background ?? this.background,
    foreground: foreground ?? this.foreground,
    decorativePrimary: decorativePrimary ?? this.decorativePrimary,
    decorativeSecondary: decorativeSecondary ?? this.decorativeSecondary,
    reward: reward ?? this.reward,
    reduceDecoration: reduceDecoration ?? this.reduceDecoration,
    surface: surface ?? this.surface,
    primary: primary ?? this.primary,
    success: success ?? this.success,
    error: error ?? this.error,
    focus: focus ?? this.focus,
    outline: outline ?? this.outline,
    spacing: spacing ?? this.spacing,
    radius: radius ?? this.radius,
  );

  @override
  DvxCourseThemeData lerp(covariant DvxCourseThemeData? other, double t) {
    if (other == null) return this;
    return DvxCourseThemeData(
      id: t < 0.5 ? id : other.id,
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      decorativePrimary: Color.lerp(
        decorativePrimary,
        other.decorativePrimary,
        t,
      )!,
      decorativeSecondary: Color.lerp(
        decorativeSecondary,
        other.decorativeSecondary,
        t,
      )!,
      reward: Color.lerp(reward, other.reward, t)!,
      reduceDecoration: t < 0.5 ? reduceDecoration : other.reduceDecoration,
      surface: Color.lerp(resolvedSurface, other.resolvedSurface, t)!,
      primary: Color.lerp(resolvedPrimary, other.resolvedPrimary, t)!,
      success: Color.lerp(resolvedSuccess, other.resolvedSuccess, t)!,
      error: Color.lerp(resolvedError, other.resolvedError, t)!,
      focus: Color.lerp(resolvedFocus, other.resolvedFocus, t)!,
      outline: Color.lerp(resolvedOutline, other.resolvedOutline, t)!,
      spacing: spacing.lerp(other.spacing, t),
      radius: radius.lerp(other.radius, t),
    );
  }
}

extension DvxCourseThemeContext on BuildContext {
  DvxCourseThemeData get courseTheme =>
      Theme.of(this).extension<DvxCourseThemeData>()!;
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
      decorativeSecondary: Color(0xFF2B0B1E),
      reward: Color(0xFFFFC42E),
      reduceDecoration: false,
      success: Color(0xFF00707F),
      error: Color(0xFFB34700),
      focus: Color(0xFF2B0B1E),
      outline: Color(0xFF2B0B1E),
    ),
    AppThemePreference.dark => const DvxCourseThemeData(
      id: 'space',
      background: Color(0xFF2B0B1E),
      foreground: Color(0xFFFFF6EC),
      decorativePrimary: Color(0xFF4A1634),
      decorativeSecondary: Color(0xFFFFC42E),
      reward: star,
      reduceDecoration: false,
      success: cosmicBlue,
      error: Color(0xFFFF9F43),
      focus: Color(0xFFFFC42E),
      outline: Color(0xFFFFF6EC),
    ),
    AppThemePreference.highContrast => const DvxCourseThemeData(
      id: 'space',
      background: Color(0xFF000000),
      foreground: Color(0xFFFFFFFF),
      decorativePrimary: Color(0xFF000000),
      decorativeSecondary: Color(0xFFFFFF00),
      reward: Color(0xFFFFFF00),
      reduceDecoration: true,
      success: Color(0xFFFFFF00),
      error: Color(0xFFFFFF00),
      focus: Color(0xFFFFFF00),
      outline: Colors.white,
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
      success: Color(0xFF00707F),
      error: Color(0xFFB34700),
      focus: Color(0xFF2B0B1E),
      outline: Color(0xFF2B0B1E),
    ),
    AppThemePreference.dark => const DvxCourseThemeData(
      id: 'default',
      background: Color(0xFF2B0B1E),
      foreground: Color(0xFFFFF6EC),
      decorativePrimary: Color(0xFF4A1634),
      decorativeSecondary: Color(0xFF3DF2FF),
      reward: Color(0xFFFFC42E),
      reduceDecoration: true,
      success: Color(0xFF3DF2FF),
      error: Color(0xFFFF9F43),
      focus: Color(0xFFFFC42E),
      outline: Color(0xFFFFF6EC),
    ),
    AppThemePreference.highContrast => const DvxCourseThemeData(
      id: 'default',
      background: Color(0xFF000000),
      foreground: Color(0xFFFFFFFF),
      decorativePrimary: Color(0xFF000000),
      decorativeSecondary: Color(0xFFFFFF00),
      reward: Color(0xFFFFFF00),
      reduceDecoration: true,
      success: Color(0xFFFFFF00),
      error: Color(0xFFFFFF00),
      focus: Color(0xFFFFFF00),
      outline: Colors.white,
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

double _lerp(double a, double b, double t) => a + (b - a) * t;

Color _contrast(Color color) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
    ? Colors.white
    : Colors.black;
