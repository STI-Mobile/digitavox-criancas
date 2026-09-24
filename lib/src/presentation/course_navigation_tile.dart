import 'package:flutter/material.dart';

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
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        minimumSize: const Size.fromHeight(64),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              completed ? Icons.check_circle_outline : Icons.menu_book_outlined,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (onPressed != null) ...[
            const SizedBox(width: 8),
            const ExcludeSemantics(child: Icon(Icons.chevron_right)),
          ],
        ],
      ),
    ),
  );
}
