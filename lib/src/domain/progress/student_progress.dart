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
    this.failedAttempts = const <String, int>{},
  });

  static const int passingAccuracyPercent = 90;

  final Set<String> completedExerciseIds;
  final int stars;
  final int tries;
  final Map<String, int> failedAttempts;

  LessonProgress completeExercise(
    String exerciseId, {
    int earnedStars = 1,
    int accuracyPercent = 100,
  }) {
    if (exerciseId.trim().isEmpty) {
      throw ArgumentError.value(exerciseId, 'exerciseId', 'não pode ser vazio');
    }
    if (earnedStars < 0) {
      throw ArgumentError.value(
        earnedStars,
        'earnedStars',
        'não pode ser negativo',
      );
    }
    if (accuracyPercent < 0 || accuracyPercent > 100) {
      throw ArgumentError.value(
        accuracyPercent,
        'accuracyPercent',
        'deve estar entre 0 e 100',
      );
    }

    final alreadyCompleted = completedExerciseIds.contains(exerciseId);
    final isPassingScore = accuracyPercent >= passingAccuracyPercent;

    final nextFailedAttempts = Map<String, int>.from(failedAttempts);
    final nextCompleted = Set<String>.from(completedExerciseIds);
    if (!alreadyCompleted ) {
      if(!isPassingScore) {
        nextFailedAttempts[exerciseId] =(nextFailedAttempts[exerciseId] ?? 0) + 1;
      }
      else
      {
        nextCompleted.add(exerciseId);
      }
    }

    

    return LessonProgress(
      completedExerciseIds: nextCompleted ,
      stars: alreadyCompleted
          ? stars
          : stars + (isPassingScore ? earnedStars : 0),
      tries: alreadyCompleted ? tries : tries + 1,
      failedAttempts: failedAttempts,
    );
  }
}

final class CourseProgress {
  const CourseProgress({this.lessons = const <String, LessonProgress>{}});

  final Map<String, LessonProgress> lessons;

  int get stars =>
      lessons.values.fold(0, (total, lesson) => total + lesson.stars);

  CourseProgress completeExercise({
    required String lessonId,
    required String exerciseId,
    int earnedStars = 1,
    int accuracyPercent = 100,
  }) {
    final currentLesson = lessons[lessonId] ?? const LessonProgress();
    return CourseProgress(
      lessons: Map.unmodifiable({
        ...lessons,
        lessonId: currentLesson.completeExercise(
          exerciseId,
          earnedStars: earnedStars,
          accuracyPercent: accuracyPercent,
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

  Map<String, int> get failedAttempts {
    final aggregated = <String, int>{};

    for (final course in courses.values) {
      for (final lesson in course.lessons.values) {
        for (final entry in lesson.failedAttempts.entries) {
          final exerciseId = entry.key;
          final attempts = entry.value;

          aggregated[exerciseId] = (aggregated[exerciseId] ?? 0) + attempts;
        }
      }
    }

    return aggregated;
  }

  StudentProgress copyWith({
    Map<String, CourseProgress>? courses,
    AppSettings? settings,
  }) => StudentProgress(
    courses: courses ?? this.courses,
    settings: settings ?? this.settings,
  );

  StudentProgress completeExercise({
    required String courseId,
    required String lessonId,
    required String exerciseId,
    int earnedStars = 1,
    int accuracyPercent = 100,
  }) {
    final currentCourse = courses[courseId] ?? const CourseProgress();
    return StudentProgress(
      courses: Map.unmodifiable({
        ...courses,
        courseId: currentCourse.completeExercise(
          lessonId: lessonId,
          exerciseId: exerciseId,
          earnedStars: earnedStars,
          accuracyPercent: accuracyPercent,
        ),
      }),
      settings: settings,
    );
  }
}
