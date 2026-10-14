enum AppThemePreference {
  standard,
  dark,
  highContrast;

  static AppThemePreference parse(String value) => values.firstWhere(
    (preference) => preference.name == value,
    orElse: () => throw ArgumentError.value(
      value,
      'value',
      'preferência de tema desconhecida',
    ),
  );

  String get label => switch (this) {
    standard => 'Padrão',
    dark => 'Escuro',
    highContrast => 'Alto contraste',
  };
}

final class AppSettings {
  const AppSettings({
    this.spokenFeedbackEnabled = true,
    this.themePreference = AppThemePreference.standard,
  });

  final bool spokenFeedbackEnabled;
  final AppThemePreference themePreference;

  bool get highContrastEnabled =>
      themePreference == AppThemePreference.highContrast;

  AppSettings copyWith({
    bool? spokenFeedbackEnabled,
    AppThemePreference? themePreference,
  }) => AppSettings(
    spokenFeedbackEnabled: spokenFeedbackEnabled ?? this.spokenFeedbackEnabled,
    themePreference: themePreference ?? this.themePreference,
  );
}

/// Measurements for one completed exercise of the current/last attempt.
final class ExerciseStatistics {
  const ExerciseStatistics({
    this.elapsedMilliseconds = 0,
    this.totalInputs = 0,
    this.correctInputs = 0,
    this.errorPairs = const <String, int>{},
  });

  final int elapsedMilliseconds;
  final int totalInputs;
  final int correctInputs;

  /// Keys identify expected → received characters, e.g. "f→j".
  final Map<String, int> errorPairs;

  void validate() {
    if (elapsedMilliseconds < 0 ||
        totalInputs < 0 ||
        correctInputs < 0 ||
        correctInputs > totalInputs ||
        errorPairs.entries.any(
          (entry) => entry.key.isEmpty || entry.value < 1,
        ) ||
        errorPairs.values.fold(0, (sum, count) => sum + count) >
            totalInputs - correctInputs) {
      throw ArgumentError('Estatísticas de exercício inconsistentes.');
    }
  }
}

final class LessonProgress {
  const LessonProgress({
    this.completedExerciseIds = const <String>{},
    this.stars = 0,
    this.tries = 0,
    this.exerciseAccuracies = const <String, int>{},
    this.exerciseStatistics = const <String, ExerciseStatistics>{},
    this.timeElapsed = 0,
    this.totalInputs = 0,
  });

  final Set<String> completedExerciseIds;

  /// Best historical reward; does not approve a subsequent attempt.
  final int stars;
  final int tries;
  final Map<String, int> exerciseAccuracies;
  final Map<String, ExerciseStatistics> exerciseStatistics;
  // Retained for callers of the earlier in-memory contract.
  final int timeElapsed;
  final int totalInputs;

  double? get averageAccuracyPercent {
    if (exerciseAccuracies.isEmpty) return null;
    final measured = exerciseAccuracies.keys.map(
      (id) => exerciseStatistics[id],
    );
    if (measured.every((stats) => stats != null && stats.totalInputs > 0)) {
      var inputs = 0;
      var correct = 0;
      for (final stats in measured) {
        inputs += stats!.totalInputs;
        correct += stats.correctInputs;
      }
      return 100 * correct / inputs;
    }
    // Legacy results do not contain counts; do not invent measurements.
    return exerciseAccuracies.values.fold(0, (sum, value) => sum + value) /
        exerciseAccuracies.length;
  }

  int starsForAccuracy(
    int lessonAccuracyPercent,
    int lessonSecChar, {
    int twoStarsMinimum = 95,
    int threeStarsMinimum = 100,
  }) {
    _validateThresholds(
      lessonAccuracyPercent,
      twoStarsMinimum,
      threeStarsMinimum,
    );
    final average = averageAccuracyPercent;
    if (average == null || average < lessonAccuracyPercent) return 0;
    if (average >= threeStarsMinimum) return 3;
    if (average >= twoStarsMinimum) return 2;
    return 1;
  }

  /// Preserve the unsuccessful diary until the next attempt starts.
  LessonProgress clearAttemptResults() => LessonProgress(
    stars: stars,
    tries: tries,
    exerciseAccuracies: exerciseAccuracies,
    exerciseStatistics: exerciseStatistics,
  );

  LessonProgress startAttempt() => LessonProgress(
    completedExerciseIds: completedExerciseIds,
    stars: stars,
    tries: tries + 1,
    exerciseAccuracies: completedExerciseIds.isEmpty
        ? const {}
        : exerciseAccuracies,
    exerciseStatistics: completedExerciseIds.isEmpty
        ? const {}
        : exerciseStatistics,
  );

  LessonProgress recordExerciseResult(
    String exerciseId, {
    int accuracyPercent = 100,
    required int lessonAccuracyPercent,
    int secChar = 0,
    required Iterable<String> lessonExerciseIds,
    int? elapsedMilliseconds,
    int? totalInputs,
    int? correctInputs,
    Map<String, int>? errorPairs,
    int twoStarsMinimum = 95,
    int threeStarsMinimum = 100,
    bool countsTowardCompletion = true,
  }) {
    if (exerciseId.trim().isEmpty ||
        accuracyPercent < 0 ||
        accuracyPercent > 100) {
      throw ArgumentError('Identificador ou precisão inválidos.');
    }
    _validateThresholds(
      lessonAccuracyPercent,
      twoStarsMinimum,
      threeStarsMinimum,
    );
    final nextCompleted = {...completedExerciseIds};
    if (countsTowardCompletion) {
      nextCompleted.add(exerciseId);
    } else {
      nextCompleted.remove(exerciseId);
    }
    final nextAccuracies = {...exerciseAccuracies, exerciseId: accuracyPercent};
    final nextStatistics = {...exerciseStatistics};
    if (totalInputs != null ||
        correctInputs != null ||
        elapsedMilliseconds != null ||
        errorPairs != null) {
      if (totalInputs == null || correctInputs == null) {
        throw ArgumentError(
          'Contagens total e correta devem ser fornecidas juntas.',
        );
      }
      final stats = ExerciseStatistics(
        elapsedMilliseconds: elapsedMilliseconds ?? 0,
        totalInputs: totalInputs,
        correctInputs: correctInputs,
        errorPairs: Map.unmodifiable(errorPairs ?? const <String, int>{}),
      );
      stats.validate();
      nextStatistics[exerciseId] = stats;
    } else {
      nextStatistics.remove(exerciseId);
    }
    final updated = LessonProgress(
      completedExerciseIds: Set.unmodifiable(nextCompleted),
      stars: stars,
      tries: tries,
      exerciseAccuracies: Map.unmodifiable(nextAccuracies),
      exerciseStatistics: Map.unmodifiable(nextStatistics),
    );
    final allIds = lessonExerciseIds.toSet();
    if (!countsTowardCompletion ||
        allIds.isEmpty ||
        !allIds.every(nextCompleted.contains)) {
      return updated;
    }
    final earned = updated.starsForAccuracy(
      lessonAccuracyPercent,
      secChar,
      twoStarsMinimum: twoStarsMinimum,
      threeStarsMinimum: threeStarsMinimum,
    );
    return LessonProgress(
      completedExerciseIds: updated.completedExerciseIds,
      stars: earned > stars ? earned : stars,
      tries: tries,
      exerciseAccuracies: updated.exerciseAccuracies,
      exerciseStatistics: updated.exerciseStatistics,
    );
  }
}

void _validateThresholds(int minimum, int two, int three) {
  if (minimum < 0 || minimum > two || two > three || three > 100) {
    throw ArgumentError('Faixas de estrelas inconsistentes.');
  }
}

final class CourseProgress {
  const CourseProgress({
    this.lessons = const <String, LessonProgress>{},
    this.completedEventIds = const <String>{},
    this.unlockedRewardIds = const <String>{},
  });
  final Map<String, LessonProgress> lessons;
  final Set<String> completedEventIds;
  final Set<String> unlockedRewardIds;
  int get stars =>
      lessons.values.fold(0, (total, lesson) => total + lesson.stars);

  CourseProgress _withLessons(Map<String, LessonProgress> next) =>
      CourseProgress(
        lessons: Map.unmodifiable(next),
        completedEventIds: completedEventIds,
        unlockedRewardIds: unlockedRewardIds,
      );

  CourseProgress recordEvent(String eventId, Iterable<String> rewardIds) {
    if (eventId.trim().isEmpty || rewardIds.any((id) => id.trim().isEmpty)) {
      throw ArgumentError('Eventos e recompensas precisam de identificadores.');
    }
    if (completedEventIds.contains(eventId)) return this;
    return CourseProgress(
      lessons: lessons,
      completedEventIds: Set.unmodifiable({...completedEventIds, eventId}),
      unlockedRewardIds: Set.unmodifiable({...unlockedRewardIds, ...rewardIds}),
    );
  }

  CourseProgress startLessonAttempt({required String lessonId}) =>
      _withLessons({
        ...lessons,
        lessonId: (lessons[lessonId] ?? const LessonProgress()).startAttempt(),
      });

  CourseProgress clearLessonAttemptResults({required String lessonId}) {
    final lesson = lessons[lessonId];
    if (lesson == null || lesson.completedExerciseIds.isEmpty) return this;
    return _withLessons({...lessons, lessonId: lesson.clearAttemptResults()});
  }

  CourseProgress recordExerciseResult({
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
  }) => _withLessons({
    ...lessons,
    lessonId: (lessons[lessonId] ?? const LessonProgress())
        .recordExerciseResult(
          exerciseId,
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
        ),
  });
}

final class StudentProgress {
  const StudentProgress({
    this.courses = const <String, CourseProgress>{},
    this.settings = const AppSettings(),
  });
  final Map<String, CourseProgress> courses;
  final AppSettings settings;
  int get totalStars =>
      courses.values.fold(0, (total, course) => total + course.stars);
  StudentProgress copyWith({
    Map<String, CourseProgress>? courses,
    AppSettings? settings,
  }) => StudentProgress(
    courses: courses ?? this.courses,
    settings: settings ?? this.settings,
  );

  StudentProgress recordCourseEvent({
    required String courseId,
    required String eventId,
    Iterable<String> rewardIds = const [],
  }) {
    final course = courses[courseId] ?? const CourseProgress();
    final next = course.recordEvent(eventId, rewardIds);
    if (identical(course, next)) return this;
    return copyWith(courses: Map.unmodifiable({...courses, courseId: next}));
  }

  StudentProgress startLessonAttempt({
    required String courseId,
    required String lessonId,
  }) => copyWith(
    courses: Map.unmodifiable({
      ...courses,
      courseId: (courses[courseId] ?? const CourseProgress())
          .startLessonAttempt(lessonId: lessonId),
    }),
  );

  StudentProgress clearLessonAttemptResults({
    required String courseId,
    required String lessonId,
  }) {
    final course = courses[courseId];
    if (course == null) return this;
    final next = course.clearLessonAttemptResults(lessonId: lessonId);
    if (identical(next, course)) return this;
    return copyWith(courses: Map.unmodifiable({...courses, courseId: next}));
  }

  StudentProgress recordExerciseResult({
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
  }) => copyWith(
    courses: Map.unmodifiable({
      ...courses,
      courseId: (courses[courseId] ?? const CourseProgress())
          .recordExerciseResult(
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
          ),
    }),
  );
}
