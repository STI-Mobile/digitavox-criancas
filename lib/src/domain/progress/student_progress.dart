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

final class LessonProgress {
  const LessonProgress({
    this.completedExerciseIds = const <String>{},
    this.stars = 0,
    this.tries = 0,
    this.exerciseAccuracies = const <String, int>{},
    this.timeElapsed = 0,
    this.totalInputs = 0,
  });

  final Set<String> completedExerciseIds;
  final int stars;
  final int tries;
  final Map<String, int> exerciseAccuracies;
  final int timeElapsed;
  final int totalInputs;

  double? get averageAccuracyPercent {
    if (exerciseAccuracies.isEmpty) return null;
    int totalAcc = 0;
    exerciseAccuracies.forEach((key, value) {
      totalAcc += value;
    });
    return totalAcc / exerciseAccuracies.length;
  }

  int starsForAccuracy(int lessonAccuracyPercent, int lessonSecChar) {
    final average = averageAccuracyPercent;
    if (average == null) return 0;
    if (average <= lessonAccuracyPercent ||
        totalInputs / timeElapsed > lessonSecChar) {
      return 0;
    }
    if (average == 100) return 3;
    if (average > 95) return 2;
    return 1;
  }

  LessonProgress clearAttemptResults() => LessonProgress(
    stars: stars,
    tries: tries,
    timeElapsed: timeElapsed,
    totalInputs: totalInputs,
  );

  LessonProgress startAttempt() => LessonProgress(
    completedExerciseIds: completedExerciseIds,
    stars: stars,
    tries: tries + 1,
    exerciseAccuracies: exerciseAccuracies,
  );

  LessonProgress recordExerciseResult(
    String exerciseId, {
    int accuracyPercent = 100,
    required int lessonAccuracyPercent,
    required int secChar,
    required Iterable<String> lessonExerciseIds,
  }) {
    if (exerciseId.trim().isEmpty) {
      throw ArgumentError.value(exerciseId, 'exerciseId', 'não pode ser vazio');
    }
    if (accuracyPercent < 0 || accuracyPercent > 100) {
      throw ArgumentError.value(
        accuracyPercent,
        'accuracyPercent',
        'deve estar entre 0 e 100',
      );
    }
    if (lessonAccuracyPercent < 0 || lessonAccuracyPercent > 100) {
      throw ArgumentError.value(
        lessonAccuracyPercent,
        'lessonAccuracyPercent',
        'deve estar entre 0 e 100',
      );
    }
    final nextCompleted = Set<String>.from(completedExerciseIds);
    nextCompleted.add(exerciseId);
    final nextAccuracies = Map<String, int>.from(exerciseAccuracies)
      ..[exerciseId] = accuracyPercent;

    final allExerciseIds = lessonExerciseIds.toSet();
    final hasCompletedLesson =
        allExerciseIds.isNotEmpty &&
        allExerciseIds.every(nextCompleted.contains);
    final updatedProgress = LessonProgress(
      completedExerciseIds: Set.unmodifiable(nextCompleted),
      stars: stars,
      tries: tries,
      exerciseAccuracies: Map.unmodifiable(nextAccuracies),
    );
    final hasAllAccuracies =
        allExerciseIds.isNotEmpty &&
        allExerciseIds.every(nextAccuracies.containsKey);
    if (!hasCompletedLesson || !hasAllAccuracies) return updatedProgress;

    final lessonStars = updatedProgress.starsForAccuracy(
      lessonAccuracyPercent,
      secChar,
    );
    return LessonProgress(
      completedExerciseIds: updatedProgress.completedExerciseIds,
      stars: lessonStars > stars ? lessonStars : stars,
      tries: tries,
      exerciseAccuracies: updatedProgress.exerciseAccuracies,
    );
  }
}

final class CourseProgress {
  const CourseProgress({this.lessons = const <String, LessonProgress>{}});

  final Map<String, LessonProgress> lessons;

  int get stars =>
      lessons.values.fold(0, (total, lesson) => total + lesson.stars);

  CourseProgress startLessonAttempt({required String lessonId}) {
    final currentLesson = lessons[lessonId] ?? const LessonProgress();
    return CourseProgress(
      lessons: Map.unmodifiable({
        ...lessons,
        lessonId: currentLesson.startAttempt(),
      }),
    );
  }

  CourseProgress clearLessonAttemptResults({required String lessonId}) {
    final lesson = lessons[lessonId];
    if (lesson == null) return this;
    return CourseProgress(
      lessons: Map.unmodifiable({
        ...lessons,
        lessonId: lesson.clearAttemptResults(),
      }),
    );
  }

  CourseProgress recordExerciseResult({
    required String lessonId,
    required String exerciseId,
    required int accuracyPercent,
    required int lessonAccuracyPercent,
    required Iterable<String> lessonExerciseIds,
    required int secChar,
  }) {
    final currentLesson = lessons[lessonId] ?? const LessonProgress();
    return CourseProgress(
      lessons: Map.unmodifiable({
        ...lessons,
        lessonId: currentLesson.recordExerciseResult(
          exerciseId,
          accuracyPercent: accuracyPercent,
          lessonAccuracyPercent: lessonAccuracyPercent,
          lessonExerciseIds: lessonExerciseIds,
          secChar: secChar,
        ),
      }),
    );
  }
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

  StudentProgress startLessonAttempt({
    required String courseId,
    required String lessonId,
  }) {
    final currentCourse = courses[courseId] ?? const CourseProgress();
    return StudentProgress(
      courses: Map.unmodifiable({
        ...courses,
        courseId: currentCourse.startLessonAttempt(lessonId: lessonId),
      }),
      settings: settings,
    );
  }

  StudentProgress clearLessonAttemptResults({
    required String courseId,
    required String lessonId,
  }) {
    final currentCourse = courses[courseId];
    if (currentCourse == null) return this;
    return StudentProgress(
      courses: Map.unmodifiable({
        ...courses,
        courseId: currentCourse.clearLessonAttemptResults(lessonId: lessonId),
      }),
      settings: settings,
    );
  }

  StudentProgress recordExerciseResult({
    required String courseId,
    required String lessonId,
    required String exerciseId,
    required int accuracyPercent,
    required int lessonAccuracyPercent,
    required Iterable<String> lessonExerciseIds,
    required int secChar,
  }) {
    final currentCourse = courses[courseId] ?? const CourseProgress();
    return StudentProgress(
      courses: Map.unmodifiable({
        ...courses,
        courseId: currentCourse.recordExerciseResult(
          lessonId: lessonId,
          exerciseId: exerciseId,
          accuracyPercent: accuracyPercent,
          lessonAccuracyPercent: lessonAccuracyPercent,
          lessonExerciseIds: lessonExerciseIds,
          secChar: secChar,
        ),
      }),
      settings: settings,
    );
  }
}
