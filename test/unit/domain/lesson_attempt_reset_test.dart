import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'preserves failed diary until retry starts and preserves lesson tries',
    () {
      const lesson = LessonProgress(
        completedExerciseIds: {'exercise-1', 'exercise-2'},
        tries: 2,
        exerciseAccuracies: {'exercise-1': 80, 'exercise-2': 90},
        exerciseStatistics: {
          'exercise-1': ExerciseStatistics(
            totalInputs: 10,
            correctInputs: 8,
            elapsedMilliseconds: 1000,
            errorPairs: {'f → j': 2},
          ),
          'exercise-2': ExerciseStatistics(
            totalInputs: 10,
            correctInputs: 9,
            elapsedMilliseconds: 1000,
            errorPairs: {'j → f': 1},
          ),
        },
      );

      final reset = lesson.clearAttemptResults();

      expect(reset.completedExerciseIds, isEmpty);
      expect(reset.exerciseAccuracies, lesson.exerciseAccuracies);
      expect(reset.exerciseStatistics['exercise-1']!.errorPairs, {'f → j': 2});
      expect(reset.starsForAccuracy(90, 0), 0);
      final retry = reset.startAttempt();
      expect(retry.completedExerciseIds, isEmpty);
      expect(retry.exerciseAccuracies, isEmpty);
      expect(retry.exerciseStatistics, isEmpty);
      expect(retry.tries, 3);
      expect(reset.stars, 0);
      expect(reset.tries, 2);
    },
  );
}
