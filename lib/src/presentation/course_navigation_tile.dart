import 'package:flutter/material.dart';

import 'design_system/tokens/dvx_tokens.dart';
import 'keyboard_navigation.dart';

/// A native button whose visible title and status also name its semantic action.
final class CourseNavigationTile extends StatelessWidget {
  const CourseNavigationTile({
    required this.title,
    required this.description,
    required this.onPressed,
    this.earnedStars,
    this.completed = false,
    this.autofocus = false,
    super.key,
  });

  final String title;
  final String description;
  final VoidCallback? onPressed;
  final int? earnedStars;
  final bool completed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DvxSpacing.sm),
    child: KeyboardNavigationLabel(
      label: [
        title,
        description,
        if (earnedStars case final stars?)
          'Melhor resultado: $stars de 3 estrelas.',
      ].join('. '),
      child: OutlinedButton(
        autofocus: autofocus,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(DvxSpacing.md),
          minimumSize: const Size.fromHeight(64),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DvxRadius.md),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                completed
                    ? Icons.check_circle_outline
                    : Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: DvxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: DvxSpacing.xs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (earnedStars case final stars?) ...[
              const SizedBox(width: DvxSpacing.sm),
              Semantics(
                label: 'Melhor resultado: $stars de 3 estrelas.',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var star = 1; star <= 3; star++)
                        Icon(
                          star <= stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: Theme.of(context)
                              .extension<DvxThemeTokens>()!
                              .accent,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (onPressed != null) ...[
              const SizedBox(width: DvxSpacing.sm),
              const ExcludeSemantics(child: Icon(Icons.chevron_right)),
            ],
          ],
        ),
      ),
    ),
  );
}
