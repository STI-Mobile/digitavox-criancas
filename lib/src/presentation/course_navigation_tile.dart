import 'package:flutter/material.dart';

import 'design_system/tokens/dvx_tokens.dart';

/// A native button whose visible title and status also name its semantic action.
final class CourseNavigationTile extends StatelessWidget {
  const CourseNavigationTile({
    required this.title,
    required this.description,
    required this.onPressed,
    this.completed = false,
    super.key,
  });

  final String title;
  final String description;
  final VoidCallback? onPressed;
  final bool completed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DvxSpacing.sm),
    child: OutlinedButton(
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
              completed ? Icons.check_circle_outline : Icons.menu_book_outlined,
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
          if (onPressed != null) ...[
            const SizedBox(width: DvxSpacing.sm),
            const ExcludeSemantics(child: Icon(Icons.chevron_right)),
          ],
        ],
      ),
    ),
  );
}
