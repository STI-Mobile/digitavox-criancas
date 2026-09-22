import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'saves and restores progress through the persistence contract',
    () async {
      final repository = InMemoryProgressRepository();
      final progress = const StudentProgress().completeExercise(
        courseId: 'course-1',
        lessonId: 'lesson-1',
        exerciseId: 'exercise-1',
      );

      await repository.save(progress);

      expect((await repository.load()).totalStars, 1);
    },
  );
}
