import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LessonProgress result(int accuracy, {int minimum = 90}) =>
      const LessonProgress().recordExerciseResult(
        'e',
        accuracyPercent: accuracy,
        lessonAccuracyPercent: minimum,
        lessonExerciseIds: const ['e'],
      );

  test('includes passing minimum, 95 and 100 in reward thresholds', () {
    expect(result(70, minimum: 70).stars, 1);
    expect(result(90).stars, 1);
    expect(result(94).stars, 1);
    expect(result(95).stars, 2);
    expect(result(99).stars, 2);
    expect(result(100).stars, 3);
    expect(result(89).stars, 0);
  });

  test('uses character counts rather than mean of unequal exercises', () {
    final progress = const LessonProgress()
        .recordExerciseResult(
          'short',
          accuracyPercent: 0,
          lessonAccuracyPercent: 90,
          lessonExerciseIds: const ['short', 'long'],
          totalInputs: 1,
          correctInputs: 0,
          elapsedMilliseconds: 1000,
          errorPairs: const {'f→j': 1},
        )
        .recordExerciseResult(
          'long',
          accuracyPercent: 100,
          lessonAccuracyPercent: 90,
          lessonExerciseIds: const ['short', 'long'],
          totalInputs: 99,
          correctInputs: 99,
          elapsedMilliseconds: 99000,
        );
    expect(progress.averageAccuracyPercent, 99);
    expect(progress.stars, 2);
    expect(progress.exerciseStatistics['short']!.errorPairs, {'f→j': 1});
  });

  test('legacy records fall back to average without invented measurements', () {
    const progress = LessonProgress(exerciseAccuracies: {'a': 80, 'b': 100});
    expect(progress.averageAccuracyPercent, 90);
    expect(progress.starsForAccuracy(90, 0), 1);
    expect(progress.starsForAccuracy(90, 99), 1);
  });

  test('accepts configurable inclusive reward thresholds', () {
    const progress = LessonProgress(exerciseAccuracies: {'a': 97});
    expect(
      progress.starsForAccuracy(
        80,
        0,
        twoStarsMinimum: 90,
        threeStarsMinimum: 97,
      ),
      3,
    );
    expect(
      () => progress.starsForAccuracy(90, 0, twoStarsMinimum: 80),
      throwsArgumentError,
    );
  });

  test(
    'failed attempt retains diary and historical reward without passing',
    () {
      final failed = const LessonProgress(stars: 3, tries: 1)
          .recordExerciseResult(
            'e',
            accuracyPercent: 50,
            lessonAccuracyPercent: 90,
            lessonExerciseIds: const ['e'],
            totalInputs: 10,
            correctInputs: 5,
            elapsedMilliseconds: 2000,
            errorPairs: const {'f→j': 5},
          )
          .clearAttemptResults();
      expect(failed.stars, 3);
      expect(failed.completedExerciseIds, isEmpty);
      expect(failed.starsForAccuracy(90, 0), 0);
      expect(failed.exerciseStatistics['e']!.correctInputs, 5);
      final retry = failed.startAttempt();
      expect(retry.tries, 2);
      expect(retry.stars, 3);
      expect(retry.exerciseAccuracies, isEmpty);
      expect(retry.exerciseStatistics, isEmpty);
    },
  );

  test('partial resumption preserves completed measurements', () {
    final partial = const LessonProgress()
        .recordExerciseResult(
          'e',
          accuracyPercent: 100,
          lessonAccuracyPercent: 90,
          lessonExerciseIds: const ['e', 'next'],
          totalInputs: 2,
          correctInputs: 2,
        )
        .startAttempt();
    expect(partial.completedExerciseIds, {'e'});
    expect(partial.exerciseStatistics['e']!.totalInputs, 2);
  });

  test(
    'timeout saves perfect partial statistics without granting completion',
    () {
      final timeout = const LessonProgress().recordExerciseResult(
        'e',
        accuracyPercent: 100,
        lessonAccuracyPercent: 90,
        lessonExerciseIds: const ['e'],
        totalInputs: 2,
        correctInputs: 2,
        elapsedMilliseconds: 3000,
        countsTowardCompletion: false,
      );
      expect(timeout.completedExerciseIds, isEmpty);
      expect(timeout.stars, 0);
      expect(timeout.exerciseStatistics['e']!.correctInputs, 2);
      final repeatTimeout =
          const LessonProgress(
            completedExerciseIds: {'e'},
            stars: 3,
          ).recordExerciseResult(
            'e',
            accuracyPercent: 100,
            lessonAccuracyPercent: 90,
            lessonExerciseIds: const ['e'],
            totalInputs: 1,
            correctInputs: 1,
            countsTowardCompletion: false,
          );
      expect(repeatTimeout.completedExerciseIds, isEmpty);
      expect(repeatTimeout.stars, 3); // Preserve history, no new award.
    },
  );

  test('rejects impossible measurements', () {
    expect(
      () =>
          const ExerciseStatistics(totalInputs: 1, correctInputs: 2).validate(),
      throwsArgumentError,
    );
    expect(
      () => const ExerciseStatistics(
        totalInputs: 1,
        errorPairs: {'f→j': 2},
      ).validate(),
      throwsArgumentError,
    );
  });
}
