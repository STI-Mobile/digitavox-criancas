import 'package:flutter/material.dart';

import '../domain/content/course_catalog.dart';
import 'design_system/components/dvx_game_components.dart';
import 'design_system/course_theme/course_theme.dart';

/// Narrative and illustration belong to the mission briefing, never practice.
final class CourseScene extends StatelessWidget {
  const CourseScene({
    required this.scene,
    required this.character,
    this.illustration,
    super.key,
  });

  final ContentScene? scene;
  final CourseCharacter? character;
  final CourseIllustration? illustration;

  @override
  Widget build(BuildContext context) {
    final spacing = context.courseTheme.spacing;
    final illustration = this.illustration;
    final character = this.character;
    final imageAsset = illustration?.imageAsset ?? character?.imageAsset;
    final description = illustration == null
        ? [
            character?.name,
            character?.imageDescription,
          ].whereType<String>().join('. ')
        : '${illustration.title}. ${illustration.imageDescription}';
    final scene = this.scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageAsset != null) ...[
          Center(
            child: Semantics(
              image: true,
              label: description,
              child: ExcludeSemantics(
                child: Image.asset(
                  imageAsset,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.md),
        ],
        if (scene != null) ...[
          Text(scene.text),
          SizedBox(height: spacing.md),
          if (scene.instruction.isNotEmpty) ...[
            DvxGameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Como praticar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Text(scene.instruction),
                ],
              ),
            ),
            SizedBox(height: spacing.md),
          ],
        ],
      ],
    );
  }
}
