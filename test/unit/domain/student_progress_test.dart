import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const exerciseIds = <String>['exercise-1', 'exercise-2', 'exercise-3'];

  StudentProgress recordScores(List<int> scores, {int threshold = 90}) {
    var progress = const StudentProgress().startLessonAttempt(
      courseId: 'course-1',
      lessonId: 'lesson-1',
    );
    for (var index = 0; index < scores.length; index++) {
      progress = progress.recordExerciseResult(
        courseId: 'course-1',
        lessonId: 'lesson-1',
        exerciseId: exerciseIds[index],
        accuracyPercent: scores[index],
        lessonAccuracyPercent: threshold,
        lessonExerciseIds: exerciseIds,
      );
    }
    return progress;
  }

  LessonProgress lessonProgress(StudentProgress progress) =>
      progress.courses['course-1']!.lessons['lesson-1']!;

  test('records lesson attempts once and stores each exercise accuracy', () {
    final progress = const StudentProgress()
        .startLessonAttempt(courseId: 'course-1', lessonId: 'lesson-1')
        .recordExerciseResult(
          courseId: 'course-1',
          lessonId: 'lesson-1',
          exerciseId: 'exercise-1',
          accuracyPercent: 80,
          lessonAccuracyPercent: 70,
          lessonExerciseIds: exerciseIds,
        )
        .recordExerciseResult(
          courseId: 'course-1',
          lessonId: 'lesson-1',
          exerciseId: 'exercise-2',
          accuracyPercent: 90,
          lessonAccuracyPercent: 70,
          lessonExerciseIds: exerciseIds,
        );
    final lesson = lessonProgress(progress);

    expect(lesson.tries, 1);
    expect(lesson.exerciseAccuracies, {'exercise-1': 80, 'exercise-2': 90});
    expect(lesson.completedExerciseIds, {'exercise-1', 'exercise-2'});
  });

  test('uses the median and awards one star above the lesson threshold', () {
    final progress = recordScores([80, 91, 99]);
    final lesson = lessonProgress(progress);

    expect(lesson.medianAccuracyPercent, 91);
    expect(lesson.starsForAccuracy(90), 1);
    expect(lesson.stars, 1);
  });

  test('awards two stars when the median is above 95 percent', () {
    final lesson = lessonProgress(recordScores([95, 96, 98]));

    expect(lesson.medianAccuracyPercent, 96);
    expect(lesson.stars, 2);
  });

  test('awards three stars only when median accuracy is 100 percent', () {
    final lesson = lessonProgress(recordScores([100, 100, 100]));

    expect(lesson.medianAccuracyPercent, 100);
    expect(lesson.stars, 3);
  });

  test('awards no stars when median is not above the lesson threshold', () {
    final lesson = lessonProgress(recordScores([80, 90, 100]));

    expect(lesson.medianAccuracyPercent, 90);
    expect(lesson.stars, 0);
  });

  test('averages the two middle values for an even-sized median', () {
    final progress = const StudentProgress()
        .startLessonAttempt(courseId: 'course-1', lessonId: 'lesson-1')
        .recordExerciseResult(
          courseId: 'course-1',
          lessonId: 'lesson-1',
          exerciseId: 'exercise-1',
          accuracyPercent: 90,
          lessonAccuracyPercent: 80,
          lessonExerciseIds: const ['exercise-1', 'exercise-2'],
        )
        .recordExerciseResult(
          courseId: 'course-1',
          lessonId: 'lesson-1',
          exerciseId: 'exercise-2',
          accuracyPercent: 95,
          lessonAccuracyPercent: 80,
          lessonExerciseIds: const ['exercise-1', 'exercise-2'],
        );

    expect(
      progress.courses['course-1']!.lessons['lesson-1']!.medianAccuracyPercent,
      92.5,
    );
  });
}
