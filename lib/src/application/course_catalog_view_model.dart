import 'package:flutter/foundation.dart';

import '../domain/content/course_catalog.dart';
import '../domain/progress/progress_repository.dart';
import '../domain/progress/student_progress.dart';

enum CourseCatalogStatus { initial, loading, ready, failure }

final class CourseCatalogViewModel extends ChangeNotifier {
  CourseCatalogViewModel({
    required this.courseCatalog,
    required this.progressRepository,
  });

  final CourseCatalog courseCatalog;
  final ProgressRepository progressRepository;

  CourseCatalogStatus _status = CourseCatalogStatus.initial;
  List<Course> _courses = const [];
  StudentProgress _progress = const StudentProgress();
  String? _errorMessage;
  Future<void> _pendingWrites = Future<void>.value();

  CourseCatalogStatus get status => _status;
  List<Course> get courses => _courses;
  StudentProgress get progress => _progress;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _status = CourseCatalogStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _pendingWrites;
      final loaded = await progressRepository.load();
      final courses = List<Course>.unmodifiable(
        await courseCatalog.loadCourses(),
      );
      final migrated = _migrateLessonAliases(loaded, courses);
      if (!identical(migrated, loaded)) {
        await progressRepository.save(migrated);
      }
      _progress = migrated;
      _courses = courses;
      _status = CourseCatalogStatus.ready;
    } on Object {
      _errorMessage = 'Não foi possível iniciar o aplicativo.';
      _status = CourseCatalogStatus.failure;
    }
    notifyListeners();
  }

  /// Content declares historical IDs; persisted progress never copies content.
  static StudentProgress _migrateLessonAliases(
    StudentProgress loaded,
    List<Course> courses,
  ) {
    var changed = false;
    final migratedCourses = {...loaded.courses};
    for (final course in courses) {
      final saved = loaded.courses[course.id];
      if (saved == null) continue;
      final lessons = {...saved.lessons};
      var courseChanged = false;
      for (final module in course.modules) {
        for (final lesson in module.lessons) {
          if (lessons.containsKey(lesson.id) ||
              lesson.legacyLessonIds.isEmpty) {
            continue;
          }
          final sources = lesson.legacyLessonIds
              .map((id) => saved.lessons[id])
              .whereType<LessonProgress>()
              .toList();
          if (sources.isEmpty) continue;
          final ids = lesson.exercises.map((exercise) => exercise.id).toSet();
          final completed = <String>{};
          final accuracies = <String, int>{};
          final statistics = <String, ExerciseStatistics>{};
          var tries = 0;
          for (final source in sources) {
            tries += source.tries;
            completed.addAll(source.completedExerciseIds.where(ids.contains));
            accuracies.addEntries(
              source.exerciseAccuracies.entries.where(
                (entry) => ids.contains(entry.key),
              ),
            );
            statistics.addEntries(
              source.exerciseStatistics.entries.where(
                (entry) => ids.contains(entry.key),
              ),
            );
          }
          final aggregate = LessonProgress(
            completedExerciseIds: Set.unmodifiable(completed),
            tries: tries,
            exerciseAccuracies: Map.unmodifiable(accuracies),
            exerciseStatistics: Map.unmodifiable(statistics),
          );
          final allFinished = ids.isNotEmpty && ids.every(completed.contains);
          final hasData = ids.every(accuracies.containsKey);
          final stars = allFinished && hasData
              ? aggregate.starsForAccuracy(
                  lesson.accuracy,
                  lesson.secChar,
                  twoStarsMinimum: course.rewards.twoStarAccuracy,
                  threeStarsMinimum: course.rewards.threeStarAccuracy,
                )
              : 0;
          lessons[lesson.id] = LessonProgress(
            // An aggregate that did not pass must offer the practice again.
            completedExerciseIds: allFinished && stars == 0
                ? const {}
                : aggregate.completedExerciseIds,
            stars: stars,
            tries: tries,
            exerciseAccuracies: aggregate.exerciseAccuracies,
            exerciseStatistics: aggregate.exerciseStatistics,
          );
          courseChanged = true;
        }
      }
      if (courseChanged) {
        migratedCourses[course.id] = CourseProgress(
          lessons: Map.unmodifiable(lessons),
          completedEventIds: saved.completedEventIds,
          unlockedRewardIds: saved.unlockedRewardIds,
        );
        changed = true;
      }
    }
    return changed
        ? loaded.copyWith(courses: Map.unmodifiable(migratedCourses))
        : loaded;
  }

  bool isExerciseCompleted({
    required String courseId,
    required String lessonId,
    required String exerciseId,
  }) {
    return _progress.courses[courseId]?.lessons[lessonId]?.completedExerciseIds
            .contains(exerciseId) ??
        false;
  }

  int lessonTries({required String courseId, required String lessonId}) =>
      _progress.courses[courseId]?.lessons[lessonId]?.tries ?? 0;

  Future<int> startLessonAttempt({
    required String courseId,
    required String lessonId,
  }) => _serialize(() async {
    if (_status != CourseCatalogStatus.ready) {
      throw StateError('O catálogo ainda não está pronto.');
    }

    final next = _progress.startLessonAttempt(
      courseId: courseId,
      lessonId: lessonId,
    );
    await progressRepository.save(next);
    _progress = next;
    notifyListeners();
    return lessonTries(courseId: courseId, lessonId: lessonId);
  });

  Future<void> clearLessonAttemptResults({
    required String courseId,
    required String lessonId,
  }) => _serialize(() async {
    if (_status != CourseCatalogStatus.ready) {
      throw StateError('O catálogo ainda não está pronto.');
    }
    final currentLesson = _progress.courses[courseId]?.lessons[lessonId];
    if (currentLesson == null || currentLesson.completedExerciseIds.isEmpty) {
      return;
    }
    final next = _progress.clearLessonAttemptResults(
      courseId: courseId,
      lessonId: lessonId,
    );
    await progressRepository.save(next);
    _progress = next;
    notifyListeners();
  });

  Future<void> recordExerciseResult({
    required String courseId,
    required String lessonId,
    required String exerciseId,
    required int accuracyPercent,
    required int lessonAccuracyPercent,
    required Iterable<String> lessonExerciseIds,
    int secChar = 0,
    int? elapsedMilliseconds,
    int? totalInputs,
    int? correctInputs,
    Map<String, int>? errorPairs,
    int twoStarsMinimum = 95,
    int threeStarsMinimum = 100,
    bool countsTowardCompletion = true,
  }) => _serialize(() async {
    if (_status != CourseCatalogStatus.ready) {
      throw StateError('O catálogo ainda não está pronto.');
    }
    final existing = _progress.courses[courseId]?.lessons[lessonId];
    if (existing?.completedExerciseIds.contains(exerciseId) ==
            countsTowardCompletion &&
        existing?.exerciseAccuracies[exerciseId] == accuracyPercent &&
        _sameStatistics(
          existing?.exerciseStatistics[exerciseId],
          elapsedMilliseconds,
          totalInputs,
          correctInputs,
          errorPairs,
        )) {
      return;
    }

    final next = _progress.recordExerciseResult(
      courseId: courseId,
      lessonId: lessonId,
      exerciseId: exerciseId,
      accuracyPercent: accuracyPercent,
      lessonAccuracyPercent: lessonAccuracyPercent,
      lessonExerciseIds: lessonExerciseIds,
      secChar: secChar,
      elapsedMilliseconds: elapsedMilliseconds,
      totalInputs: totalInputs,
      correctInputs: correctInputs,
      errorPairs: errorPairs,
      twoStarsMinimum: twoStarsMinimum,
      threeStarsMinimum: threeStarsMinimum,
      countsTowardCompletion: countsTowardCompletion,
    );
    await progressRepository.save(next);
    _progress = next;
    notifyListeners();
  });

  Future<void> recordCourseEvent({
    required String courseId,
    required String eventId,
    Iterable<String> rewardIds = const [],
  }) => _serialize(() async {
    if (_status != CourseCatalogStatus.ready) {
      throw StateError('O catálogo ainda não está pronto.');
    }
    final next = _progress.recordCourseEvent(
      courseId: courseId,
      eventId: eventId,
      rewardIds: rewardIds,
    );
    if (identical(next, _progress)) return;
    await progressRepository.save(next);
    _progress = next;
    notifyListeners();
  });

  static bool _sameStatistics(
    ExerciseStatistics? stats,
    int? elapsedMilliseconds,
    int? totalInputs,
    int? correctInputs,
    Map<String, int>? errorPairs,
  ) {
    if (stats == null) {
      return elapsedMilliseconds == null &&
          totalInputs == null &&
          correctInputs == null &&
          errorPairs == null;
    }
    return stats.elapsedMilliseconds == (elapsedMilliseconds ?? 0) &&
        stats.totalInputs == totalInputs &&
        stats.correctInputs == correctInputs &&
        mapEquals(stats.errorPairs, errorPairs ?? const <String, int>{});
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _pendingWrites.then((_) => action());
    _pendingWrites = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<void> updateThemePreference(AppThemePreference preference) =>
      _serialize(() async {
        if (_status != CourseCatalogStatus.ready) {
          throw StateError('O catálogo ainda não está pronto.');
        }
        if (_progress.settings.themePreference == preference) return;

        final next = _progress.copyWith(
          settings: _progress.settings.copyWith(themePreference: preference),
        );
        await progressRepository.save(next);
        _progress = next;
        notifyListeners();
      });
}
