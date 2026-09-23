import 'package:flutter/material.dart';

import '../domain/content/course_catalog.dart';

final class CourseScene extends StatelessWidget {
  const CourseScene({required this.scene, required this.character, super.key});

  final ContentScene? scene;
  final CourseCharacter? character;

  @override
  Widget build(BuildContext context) {
    final character = this.character;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (character != null) ...[
          Center(
            child: Semantics(
              container: true,
              image: true,
              label: '${character.name}. ${character.imageDescription}',
              child: ExcludeSemantics(
                child: Image.asset(
                  character.imageAsset,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person_outline, size: 64),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(character.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        if (scene != null) Text(scene!.text),
        if (scene != null || character != null) const SizedBox(height: 20),
      ],
    );
  }
}
