import 'package:flutter/material.dart';

@immutable
final class DvxAccessibilityTokens
    extends ThemeExtension<DvxAccessibilityTokens> {
  const DvxAccessibilityTokens({
    required this.focusWidth,
    required this.borderWidth,
    required this.highContrast,
  });

  final double focusWidth;
  final double borderWidth;
  final bool highContrast;

  @override
  DvxAccessibilityTokens copyWith({
    double? focusWidth,
    double? borderWidth,
    bool? highContrast,
  }) => DvxAccessibilityTokens(
    focusWidth: focusWidth ?? this.focusWidth,
    borderWidth: borderWidth ?? this.borderWidth,
    highContrast: highContrast ?? this.highContrast,
  );

  @override
  DvxAccessibilityTokens lerp(
    covariant DvxAccessibilityTokens? other,
    double t,
  ) {
    if (other == null) return this;
    return DvxAccessibilityTokens(
      focusWidth: focusWidth + (other.focusWidth - focusWidth) * t,
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
      highContrast: t < 0.5 ? highContrast : other.highContrast,
    );
  }
}

extension DvxAccessibilityContext on BuildContext {
  DvxAccessibilityTokens get accessibilityTokens =>
      Theme.of(this).extension<DvxAccessibilityTokens>()!;
}
