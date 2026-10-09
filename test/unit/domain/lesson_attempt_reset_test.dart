import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'clears results from a zero-star attempt but preserves lesson tries',
    () {
      const lesson = LessonProgress(
        completedExerciseIds: {'exercise-1', 'exercise-2'},
        tries: 2,
        exerciseAccuracies: {'exercise-1': 80, 'exercise-2': 90},
      );

      final reset = lesson.clearAttemptResults();

      expect(reset.completedExerciseIds, isEmpty);
      expect(reset.exerciseAccuracies, isEmpty);
      expect(reset.stars, 0);
      expect(reset.tries, 2);
    },
  );
}
