import 'package:flutter/material.dart';

import '../../../domain/progress/student_progress.dart';
import '../course_theme/course_theme.dart';
import '../tokens/dvx_tokens.dart';

final class DvxGameScaffold extends StatelessWidget {
  const DvxGameScaffold({
    required this.courseTheme,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    super.key,
  });

  final DvxCourseThemeData courseTheme;
  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: courseTheme.background,
    appBar: AppBar(
      backgroundColor: courseTheme.background,
      leading: leading,
      title: Text(title),
      actions: actions,
    ),
    body: Stack(
      children: [
        Positioned.fill(child: _CourseBackdrop(theme: courseTheme)),
        SafeArea(child: body),
      ],
    ),
  );
}

final class _CourseBackdrop extends StatelessWidget {
  const _CourseBackdrop({required this.theme});

  final DvxCourseThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (theme.reduceDecoration) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.background, theme.decorativePrimary],
          ),
        ),
        child: Stack(
          children: [
            _star(const Alignment(-0.84, -0.88), 5),
            _star(const Alignment(0.76, -0.72), 4),
            _star(const Alignment(-0.66, 0.16), 3),
            _star(const Alignment(0.88, 0.52), 5),
          ],
        ),
      ),
    );
  }

  Widget _star(Alignment alignment, double size) => Align(
    alignment: alignment,
    child: Icon(Icons.star, size: size, color: theme.reward.withAlpha(150)),
  );
}

final class DvxGameCard extends StatelessWidget {
  const DvxGameCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: padding ?? const EdgeInsets.all(DvxSpacing.md),
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
          const SizedBox(width: DvxSpacing.xs),
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
          borderRadius: BorderRadius.circular(DvxRadius.sm),
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
    final singleKey = value.runes.length == 1;
    return Semantics(
      label: 'Exercício: $value. Próxima tecla: $nextCharacter.',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.symmetric(
            horizontal: DvxSpacing.lg,
            vertical: DvxSpacing.md,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(DvxRadius.lg),
            border: Border.all(
              color: scheme.primary,
              width: context.dvxTokens.highContrast ? 4 : 2,
            ),
            boxShadow: context.dvxTokens.highContrast
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toUpperCase(),
              style:
                  (singleKey
                          ? Theme.of(context).textTheme.displayLarge
                          : Theme.of(context).textTheme.headlineMedium)
                      ?.copyWith(color: scheme.primary),
              textAlign: TextAlign.center,
            ),
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
    final tokens = context.dvxTokens;
    final (icon, color) = switch (kind) {
      DvxFeedbackKind.waiting => (Icons.keyboard, scheme.primary),
      DvxFeedbackKind.success => (Icons.check_circle_outline, tokens.success),
      DvxFeedbackKind.error => (Icons.error_outline, scheme.error),
      DvxFeedbackKind.completed => (Icons.celebration_outlined, tokens.accent),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(DvxSpacing.md),
          decoration: BoxDecoration(
            color: tokens.surfaceVariant,
            border: Border.all(color: color, width: tokens.borderWidth + 1),
            borderRadius: BorderRadius.circular(DvxRadius.md),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: DvxSpacing.sm),
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
    super.key,
  });

  final AppThemePreference preference;
  final ValueChanged<AppThemePreference> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<AppThemePreference>(
    tooltip: 'Alterar tema visual',
    initialValue: preference,
    onSelected: onSelected,
    icon: const Icon(Icons.contrast),
    itemBuilder: (context) => [
      for (final value in AppThemePreference.values)
        PopupMenuItem(
          value: value,
          child: Row(
            children: [
              Icon(
                value == preference
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              const SizedBox(width: DvxSpacing.sm),
              Expanded(child: Text(value.label)),
            ],
          ),
        ),
    ],
  );
}
