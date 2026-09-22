import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completing an exercise records it and awards one star', () {
    final progress = const StudentProgress().completeExercise(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
    );

    expect(progress.totalStars, 1);
    expect(
      progress.courses['course-1']!.lessons['lesson-1']!.completedExerciseIds,
      contains('exercise-1'),
    );
  });

  test('repeating a completed exercise does not duplicate its reward', () {
    final firstCompletion = const StudentProgress().completeExercise(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
    );
    final repeatedCompletion = firstCompletion.completeExercise(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
    );

    expect(repeatedCompletion.totalStars, 1);
  });
}
