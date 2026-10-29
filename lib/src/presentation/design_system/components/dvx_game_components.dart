import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/progress/student_progress.dart';
import '../../keyboard_navigation.dart';
import '../course_theme/course_theme.dart';
import '../tokens/accessibility_tokens.dart';

final class DvxGameScaffold extends StatelessWidget {
  const DvxGameScaffold({
    required this.courseTheme,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    this.bottomNavigationBar,
    super.key,
  });

  final DvxCourseThemeData courseTheme;
  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final accessibility = appTheme.extension<DvxAccessibilityTokens>()!;
    final radius = courseTheme.radius;
    final textTheme = appTheme.textTheme.apply(
      bodyColor: courseTheme.foreground,
      displayColor: courseTheme.foreground,
    );
    final scheme = appTheme.colorScheme.copyWith(
      brightness: ThemeData.estimateBrightnessForColor(courseTheme.background),
      primary: courseTheme.resolvedPrimary,
      onPrimary: courseTheme.onPrimary,
      secondary: courseTheme.decorativeSecondary,
      onSecondary: courseTheme.onSecondary,
      error: courseTheme.resolvedError,
      onError: courseTheme.onError,
      surface: courseTheme.resolvedSurface,
      onSurface: courseTheme.foreground,
      tertiary: courseTheme.reward,
      onTertiary: courseTheme.onReward,
      outline: courseTheme.resolvedOutline,
      outlineVariant: courseTheme.decorativePrimary,
    );
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(
          color: courseTheme.resolvedFocus,
          width: accessibility.focusWidth,
        );
      }
      return null;
    });
    final outlinedSide = WidgetStateProperty.resolveWith<BorderSide>((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(
          color: courseTheme.resolvedFocus,
          width: accessibility.focusWidth,
        );
      }
      return BorderSide(
        color: courseTheme.resolvedOutline,
        width: accessibility.highContrast ? accessibility.borderWidth : 1.5,
      );
    });
    final scopedTheme = appTheme.copyWith(
      brightness: scheme.brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: courseTheme.background,
      canvasColor: courseTheme.background,
      focusColor: courseTheme.resolvedFocus,
      hoverColor: courseTheme.resolvedFocus.withAlpha(20),
      highlightColor: courseTheme.resolvedFocus.withAlpha(24),
      splashColor: courseTheme.resolvedFocus.withAlpha(28),
      iconTheme: appTheme.iconTheme.copyWith(color: courseTheme.foreground),
      primaryIconTheme: appTheme.primaryIconTheme.copyWith(
        color: courseTheme.foreground,
      ),
      appBarTheme: appTheme.appBarTheme.copyWith(
        backgroundColor: courseTheme.background,
        foregroundColor: courseTheme.foreground,
      ),
      cardTheme: appTheme.cardTheme.copyWith(
        color: courseTheme.resolvedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.md),
          side:
              accessibility.highContrast ||
                  courseTheme.resolvedSurface == courseTheme.background
              ? BorderSide(
                  color: courseTheme.resolvedOutline,
                  width: accessibility.highContrast
                      ? accessibility.borderWidth
                      : 1,
                )
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: courseTheme.onPrimary,
          backgroundColor: courseTheme.resolvedPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.md),
          ),
        ).copyWith(side: focusSide),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: courseTheme.resolvedPrimary,
          minimumSize: const Size(48, 56),
          side: BorderSide(
            color: courseTheme.resolvedOutline,
            width: accessibility.highContrast ? accessibility.borderWidth : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.md),
          ),
        ).copyWith(side: outlinedSide),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: courseTheme.resolvedPrimary,
          minimumSize: const Size(48, 48),
        ).copyWith(side: focusSide),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: courseTheme.resolvedPrimary,
        linearTrackColor: courseTheme.resolvedSurface,
      ),
      popupMenuTheme: appTheme.popupMenuTheme.copyWith(
        color: courseTheme.resolvedSurface,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.md),
        ),
      ),
      dialogTheme: appTheme.dialogTheme.copyWith(
        backgroundColor: courseTheme.resolvedSurface,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.md),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[accessibility, courseTheme],
    );

    return Theme(
      data: scopedTheme,
      child: Scaffold(
        backgroundColor: courseTheme.background,
        bottomNavigationBar: bottomNavigationBar,
        appBar: AppBar(
          backgroundColor: courseTheme.background,
          leading: leading,
          title: Text(title),
          actions: actions,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _CourseBackdrop(theme: courseTheme)),
            SafeArea(child: body),
          ],
        ),
      ),
    );
  }
}

final class _CourseBackdrop extends StatelessWidget {
  const _CourseBackdrop({required this.theme});

  final DvxCourseThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (theme.reduceDecoration) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: DecoratedBox(decoration: BoxDecoration(color: theme.background)),
    );
  }
}

final class DvxGameCard extends StatelessWidget {
  const DvxGameCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: padding ?? EdgeInsets.all(context.courseTheme.spacing.md),
      child: child,
    ),
  );
}

final class DvxStars extends StatelessWidget {
  const DvxStars({required this.count, required this.color, super.key});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '$count estrelas conquistadas',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color),
          SizedBox(width: context.courseTheme.spacing.xs),
          Text('$count', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
}

final class DvxProgressIndicator extends StatelessWidget {
  const DvxProgressIndicator({
    required this.completed,
    required this.total,
    super.key,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : completed / total;
    return Semantics(
      label: '$completed de $total exercícios concluídos',
      value: '${(value * 100).round()} por cento',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.courseTheme.radius.sm),
          child: LinearProgressIndicator(value: value, minHeight: 12),
        ),
      ),
    );
  }
}

final class DvxKeyPrompt extends StatelessWidget {
  const DvxKeyPrompt({
    required this.value,
    required this.nextCharacter,
    super.key,
  });

  final String value;
  final String nextCharacter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.courseTheme.spacing;
    final radius = context.courseTheme.radius;
    final shortTarget = value.runes.length <= 5;
    return Semantics(
      label: 'Exercício: $value. Próxima tecla: $nextCharacter.',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.md,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(radius.lg),
            border: Border.all(
              color: scheme.primary,
              width: context.accessibilityTokens.highContrast ? 4 : 2,
            ),
            boxShadow: context.accessibilityTokens.highContrast
                ? null
                : [
                    BoxShadow(
                      color: scheme.primary.withAlpha(35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            value.toUpperCase(),
            style:
                (shortTarget
                        ? Theme.of(context).textTheme.displayLarge
                        : Theme.of(context).textTheme.headlineMedium)
                    ?.copyWith(color: scheme.primary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

enum DvxFeedbackKind { waiting, success, error, completed }

final class DvxFeedback extends StatelessWidget {
  const DvxFeedback({required this.kind, required this.message, super.key});

  final DvxFeedbackKind kind;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final courseTheme = context.courseTheme;
    final spacing = courseTheme.spacing;
    final radius = courseTheme.radius;
    final (icon, color) = switch (kind) {
      DvxFeedbackKind.waiting => (Icons.keyboard, scheme.primary),
      DvxFeedbackKind.success => (
        Icons.check_circle_outline,
        courseTheme.resolvedSuccess,
      ),
      DvxFeedbackKind.error => (Icons.error_outline, courseTheme.resolvedError),
      DvxFeedbackKind.completed => (
        Icons.celebration_outlined,
        courseTheme.reward,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: courseTheme.resolvedSurface,
            border: Border.all(
              color: color,
              width: context.accessibilityTokens.borderWidth + 1,
            ),
            borderRadius: BorderRadius.circular(radius.md),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(width: spacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

final class DvxThemeSelector extends StatelessWidget {
  const DvxThemeSelector({
    required this.preference,
    required this.onSelected,
    required this.onAnnounce,
    super.key,
  });

  final AppThemePreference preference;
  final ValueChanged<AppThemePreference> onSelected;
  final Future<void> Function(String) onAnnounce;

  @override
  Widget build(BuildContext context) => KeyboardNavigationLabel(
    label: 'Alterar tema visual. ${preference.label}',
    child: PopupMenuButton<AppThemePreference>(
      tooltip: 'Alterar tema visual',
      initialValue: preference,
      onSelected: onSelected,
      icon: const Icon(Icons.contrast),
      itemBuilder: (context) => [
        for (final value in AppThemePreference.values)
          _ThemeMenuItem(
            value: value,
            onAnnounce: onAnnounce,
            child: Semantics(
              selected: value == preference,
              child: Row(
                children: [
                  Icon(
                    value == preference
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  SizedBox(width: context.courseTheme.spacing.sm),
                  Expanded(child: Text(value.label)),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// Keeps native popup activation and semantics while observing its item focus.
final class _ThemeMenuItem extends PopupMenuItem<AppThemePreference> {
  const _ThemeMenuItem({
    required super.value,
    required super.child,
    required this.onAnnounce,
  });

  final Future<void> Function(String) onAnnounce;

  @override
  PopupMenuItemState<AppThemePreference, _ThemeMenuItem> createState() =>
      _ThemeMenuItemState();
}

final class _ThemeMenuItemState
    extends PopupMenuItemState<AppThemePreference, _ThemeMenuItem> {
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    includeSemantics: false,
    onFocusChange: (focused) {
      if (focused) unawaited(widget.onAnnounce(widget.value!.label));
    },
    child: super.build(context),
  );
}
