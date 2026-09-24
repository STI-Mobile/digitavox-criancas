import 'package:flutter/material.dart';

abstract final class DvxSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class DvxRadius {
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
}

@immutable
final class DvxThemeTokens extends ThemeExtension<DvxThemeTokens> {
  const DvxThemeTokens({
    required this.accent,
    required this.success,
    required this.focus,
    required this.textSecondary,
    required this.surfaceVariant,
    required this.focusWidth,
    required this.borderWidth,
    required this.highContrast,
  });

  final Color accent;
  final Color success;
  final Color focus;
  final Color textSecondary;
  final Color surfaceVariant;
  final double focusWidth;
  final double borderWidth;
  final bool highContrast;

  @override
  DvxThemeTokens copyWith({
    Color? accent,
    Color? success,
    Color? focus,
    Color? textSecondary,
    Color? surfaceVariant,
    double? focusWidth,
    double? borderWidth,
    bool? highContrast,
  }) => DvxThemeTokens(
    accent: accent ?? this.accent,
    success: success ?? this.success,
    focus: focus ?? this.focus,
    textSecondary: textSecondary ?? this.textSecondary,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    focusWidth: focusWidth ?? this.focusWidth,
    borderWidth: borderWidth ?? this.borderWidth,
    highContrast: highContrast ?? this.highContrast,
  );

  @override
  DvxThemeTokens lerp(covariant DvxThemeTokens? other, double t) {
    if (other == null) return this;
    return DvxThemeTokens(
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      focusWidth: focusWidth + (other.focusWidth - focusWidth) * t,
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
      highContrast: t < 0.5 ? highContrast : other.highContrast,
    );
  }
}

extension DvxThemeContext on BuildContext {
  DvxThemeTokens get dvxTokens => Theme.of(this).extension<DvxThemeTokens>()!;
}
