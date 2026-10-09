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

  CourseCatalogStatus get status => _status;
  List<Course> get courses => _courses;
  StudentProgress get progress => _progress;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _status = CourseCatalogStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _progress = await progressRepository.load();
      _courses = List.unmodifiable(await courseCatalog.loadCourses());
      _status = CourseCatalogStatus.ready;
    } on Object {
      _errorMessage = 'Não foi possível iniciar o aplicativo.';
      _status = CourseCatalogStatus.failure;
    }
    notifyListeners();
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
  }) async {
    if (_status != CourseCatalogStatus.ready) {
      throw StateError('O catálogo ainda não está pronto.');
    }

    _progress = _progress.startLessonAttempt(
      courseId: courseId,
      lessonId: lessonId,
    );
    await progressRepository.save(_progress);
    notifyListeners();
    return lessonTries(courseId: courseId, lessonId: lessonId);
  }

  Future<void> recordExerciseResult({
    required String courseId,
    required String lessonId,
    required String exerciseId,
    required int accuracyPercent,
    required int lessonAccuracyPercent,
    required Iterable<String> lessonExerciseIds,
    required int secChar,
  }) async {
    if (_status != CourseCatalogStatus.ready) {
      throw StateError('O catálogo ainda não está pronto.');
    }
    final existing = _progress.courses[courseId]?.lessons[lessonId];
    if (existing?.completedExerciseIds.contains(exerciseId) == true &&
        existing?.exerciseAccuracies[exerciseId] == accuracyPercent) {
      return;
    }

    _progress = _progress.recordExerciseResult(
      courseId: courseId,
      lessonId: lessonId,
      exerciseId: exerciseId,
      accuracyPercent: accuracyPercent,
      lessonAccuracyPercent: lessonAccuracyPercent,
      lessonExerciseIds: lessonExerciseIds,
      secChar: secChar
    );
    await progressRepository.save(_progress);
    notifyListeners();
  }

  Future<void> updateThemePreference(AppThemePreference preference) async {
    if (_status != CourseCatalogStatus.ready) {
      throw StateError('O catálogo ainda não está pronto.');
    }
    if (_progress.settings.themePreference == preference) return;

    _progress = _progress.copyWith(
      settings: _progress.settings.copyWith(themePreference: preference),
    );
    await progressRepository.save(_progress);
    notifyListeners();
  }
}
