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
  });

  final Set<String> completedExerciseIds;
  final int stars;

  LessonProgress completeExercise(String exerciseId, {int earnedStars = 1}) {
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

    final alreadyCompleted = completedExerciseIds.contains(exerciseId);
    return LessonProgress(
      completedExerciseIds: Set.unmodifiable({
        ...completedExerciseIds,
        exerciseId,
      }),
      stars: alreadyCompleted ? stars : stars + earnedStars,
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
  }) {
    final currentLesson = lessons[lessonId] ?? const LessonProgress();
    return CourseProgress(
      lessons: Map.unmodifiable({
        ...lessons,
        lessonId: currentLesson.completeExercise(
          exerciseId,
          earnedStars: earnedStars,
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

  StudentProgress completeExercise({
    required String courseId,
    required String lessonId,
    required String exerciseId,
    int earnedStars = 1,
  }) {
    final currentCourse = courses[courseId] ?? const CourseProgress();
    return StudentProgress(
      courses: Map.unmodifiable({
        ...courses,
        courseId: currentCourse.completeExercise(
          lessonId: lessonId,
          exerciseId: exerciseId,
          earnedStars: earnedStars,
        ),
      }),
      settings: settings,
    );
  }
}
