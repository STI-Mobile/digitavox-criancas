import 'package:digitavox_criancas/src/application/course_catalog_view_model.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/data/persistence/local_progress_repository.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:digitavox_criancas/src/domain/progress/progress_repository.dart';
import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads courses and persists an exercise completion', () async {
    final repository = InMemoryProgressRepository();
    final viewModel = CourseCatalogViewModel(
      courseCatalog: const _FakeCourseCatalog(),
      progressRepository: repository,
    );

    await viewModel.initialize();
    await viewModel.startLessonAttempt(
      courseId: 'course-1',
      lessonId: 'lesson-1',
    );
    await viewModel.recordExerciseResult(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
      accuracyPercent: 100,
      lessonAccuracyPercent: 90,
      lessonExerciseIds: const ['exercise-1'],
    );

    expect(viewModel.status, CourseCatalogStatus.ready);
    expect(viewModel.courses.single.title, 'Curso demo');
    expect(viewModel.progress.totalStars, 3);
    expect((await repository.load()).totalStars, 3);
  });

  test('loads persisted progress before loading the catalog', () async {
    final events = <String>[];
    final viewModel = CourseCatalogViewModel(
      courseCatalog: _RecordingCourseCatalog(events),
      progressRepository: _RecordingProgressRepository(events),
    );

    await viewModel.initialize();

    expect(events, <String>['progress', 'catalog']);
    expect(viewModel.status, CourseCatalogStatus.ready);
  });

  test(
    'reports a stable user-facing error when content loading fails',
    () async {
      final viewModel = CourseCatalogViewModel(
        courseCatalog: const _FailingCourseCatalog(),
        progressRepository: InMemoryProgressRepository(),
      );

      await viewModel.initialize();

      expect(viewModel.status, CourseCatalogStatus.failure);
      expect(viewModel.errorMessage, isNotEmpty);
    },
  );

  test('does not persist a duplicate exercise completion', () async {
    final repository = _CountingProgressRepository();
    final viewModel = CourseCatalogViewModel(
      courseCatalog: const _FakeCourseCatalog(),
      progressRepository: repository,
    );
    await viewModel.initialize();

    await viewModel.startLessonAttempt(
      courseId: 'course-1',
      lessonId: 'lesson-1',
    );
    await viewModel.recordExerciseResult(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
      accuracyPercent: 91,
      lessonAccuracyPercent: 90,
      lessonExerciseIds: const ['exercise-1'],
    );
    await viewModel.recordExerciseResult(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
      accuracyPercent: 91,
      lessonAccuracyPercent: 90,
      lessonExerciseIds: const ['exercise-1'],
    );

    expect(viewModel.progress.totalStars, 1);
    expect(repository.saveCount, 2);
  });

  test('records ceremony only once including simultaneous requests', () async {
    final repository = _CountingProgressRepository();
    final model = CourseCatalogViewModel(
      courseCatalog: const _FakeCourseCatalog(),
      progressRepository: repository,
    );
    await model.initialize();
    Future<void> grant() => model.recordCourseEvent(
      courseId: 'course-1',
      eventId: 'launch',
      rewardIds: const ['bronze', 'alien-1'],
    );
    await Future.wait([grant(), grant()]);
    await grant();
    expect(repository.saveCount, 1);
    expect(model.progress.courses['course-1']!.completedEventIds, {'launch'});
    expect(model.progress.courses['course-1']!.unlockedRewardIds, {
      'bronze',
      'alien-1',
    });
  });

  test(
    'failed writes remain retryable without publishing unsaved ceremony',
    () async {
      final repository = _FailingWriteRepository();
      final model = CourseCatalogViewModel(
        courseCatalog: const _FakeCourseCatalog(),
        progressRepository: repository,
      );
      await model.initialize();
      Future<void> grant() => model.recordCourseEvent(
        courseId: 'course-1',
        eventId: 'launch',
        rewardIds: const ['bronze'],
      );
      await expectLater(grant(), throwsStateError);
      expect(model.progress.courses, isEmpty);
      repository.fail = false;
      await grant();
      expect(model.progress.courses['course-1']!.unlockedRewardIds, {'bronze'});
    },
  );

  test(
    'different measurements with identical precision are persisted',
    () async {
      final repository = _CountingProgressRepository();
      final model = CourseCatalogViewModel(
        courseCatalog: const _FakeCourseCatalog(),
        progressRepository: repository,
      );
      await model.initialize();
      Future<void> record(int elapsed) => model.recordExerciseResult(
        courseId: 'course-1',
        lessonId: 'lesson-1',
        exerciseId: 'exercise-1',
        accuracyPercent: 100,
        lessonAccuracyPercent: 90,
        lessonExerciseIds: const ['exercise-1'],
        totalInputs: 2,
        correctInputs: 2,
        elapsedMilliseconds: elapsed,
      );
      await record(1000);
      await record(1000);
      await record(2000);
      expect(repository.saveCount, 2);
      expect(
        model
            .progress
            .courses['course-1']!
            .lessons['lesson-1']!
            .exerciseStatistics['exercise-1']!
            .elapsedMilliseconds,
        2000,
      );
    },
  );

  test('timeout records measurements without completion or rewards', () async {
    final repository = _CountingProgressRepository();
    final model = CourseCatalogViewModel(
      courseCatalog: const _FakeCourseCatalog(),
      progressRepository: repository,
    );
    await model.initialize();
    Future<void> timeout() => model.recordExerciseResult(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
      accuracyPercent: 100,
      lessonAccuracyPercent: 90,
      lessonExerciseIds: const ['exercise-1'],
      totalInputs: 1,
      correctInputs: 1,
      elapsedMilliseconds: 1000,
      countsTowardCompletion: false,
    );
    await timeout();
    await timeout();
    expect(repository.saveCount, 1);
    expect(
      model.isExerciseCompleted(
        courseId: 'course-1',
        lessonId: 'lesson-1',
        exerciseId: 'exercise-1',
      ),
      isFalse,
    );
    final course = model.progress.courses['course-1']!;
    expect(course.stars, 0);
    expect(course.completedEventIds, isEmpty);
    expect(course.unlockedRewardIds, isEmpty);
    expect(
      course.lessons['lesson-1']!.exerciseStatistics['exercise-1']!.totalInputs,
      1,
    );
  });

  test(
    'migrates split legacy lessons once using filtered measurements',
    () async {
      final repository = _CountingProgressRepository()
        ..progress = _legacyProgress();
      final model = CourseCatalogViewModel(
        courseCatalog: const _AliasCourseCatalog(),
        progressRepository: repository,
      );
      await model.initialize();
      expect(model.status, CourseCatalogStatus.ready);
      final course = model.progress.courses['course-1']!;
      final aggregate = course.lessons['unified']!;
      expect(aggregate.completedExerciseIds, {'code', 'words'});
      expect(aggregate.exerciseAccuracies, {'code': 100, 'words': 90});
      expect(
        aggregate.exerciseStatistics.keys,
        unorderedEquals(['code', 'words']),
      );
      expect(aggregate.averageAccuracyPercent, 99); // 99/100, not mean95.
      expect(aggregate.stars, 2);
      expect(aggregate.tries, 5);
      expect(course.lessons['m1-7a-prova-codigo'], isNotNull);
      expect(course.lessons['m1-7b-prova-mensagens'], isNotNull);
      expect(course.completedEventIds, {'previous-event'});
      expect(course.unlockedRewardIds, {'previous-reward'});
      expect(course.completedEventIds, isNot(contains('ceremony')));
      expect(repository.saveCount, 1);
      await model.initialize();
      expect(repository.saveCount, 1);
      expect(model.progress.courses['course-1']!.lessons['unified']!.tries, 5);
    },
  );

  test(
    'legacy failed aggregate keeps diary and clears IDs to allow retry',
    () async {
      final repository = _CountingProgressRepository()
        ..progress = _legacyProgress(failed: true);
      final model = CourseCatalogViewModel(
        courseCatalog: const _AliasCourseCatalog(),
        progressRepository: repository,
      );
      await model.initialize();
      final aggregate = model.progress.courses['course-1']!.lessons['unified']!;
      expect(
        aggregate.stars,
        0,
      ); // Source best stars do not approve this result.
      expect(aggregate.completedExerciseIds, isEmpty);
      expect(aggregate.exerciseStatistics, hasLength(2));
      expect(aggregate.averageAccuracyPercent, 0);
    },
  );

  test(
    'does not write aliases migration when there are no source records',
    () async {
      final repository = _CountingProgressRepository();
      final model = CourseCatalogViewModel(
        courseCatalog: const _AliasCourseCatalog(),
        progressRepository: repository,
      );
      await model.initialize();
      expect(repository.saveCount, 0);
      expect(model.progress.courses, isEmpty);
    },
  );

  test(
    'reports failure without publishing migration when storage rejects it',
    () async {
      final repository = _AliasFailingWriteRepository();
      final model = CourseCatalogViewModel(
        courseCatalog: const _AliasCourseCatalog(),
        progressRepository: repository,
      );
      await model.initialize();
      expect(model.status, CourseCatalogStatus.failure);
      expect(model.progress.courses, isEmpty);
      expect(model.errorMessage, isNotEmpty);
    },
  );

  test('persists the selected application theme', () async {
    final repository = InMemoryProgressRepository();
    final viewModel = CourseCatalogViewModel(
      courseCatalog: const _FakeCourseCatalog(),
      progressRepository: repository,
    );
    await viewModel.initialize();

    await viewModel.updateThemePreference(AppThemePreference.dark);

    expect(
      viewModel.progress.settings.themePreference,
      AppThemePreference.dark,
    );
    expect(
      (await repository.load()).settings.themePreference,
      AppThemePreference.dark,
    );
  });

  test('restores completion after recreating the application state', () async {
    final store = _MemoryDocumentStore();
    final firstSession = CourseCatalogViewModel(
      courseCatalog: const _FakeCourseCatalog(),
      progressRepository: LocalProgressRepository(store: store),
    );
    await firstSession.initialize();
    await firstSession.startLessonAttempt(
      courseId: 'course-1',
      lessonId: 'lesson-1',
    );
    await firstSession.recordExerciseResult(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
      accuracyPercent: 91,
      lessonAccuracyPercent: 90,
      lessonExerciseIds: const ['exercise-1'],
    );

    final restartedSession = CourseCatalogViewModel(
      courseCatalog: const _FakeCourseCatalog(),
      progressRepository: LocalProgressRepository(store: store),
    );
    await restartedSession.initialize();

    expect(restartedSession.progress.totalStars, 1);
    expect(
      restartedSession.isExerciseCompleted(
        courseId: 'course-1',
        lessonId: 'lesson-1',
        exerciseId: 'exercise-1',
      ),
      isTrue,
    );
  });
}

final class _MemoryDocumentStore implements ProgressDocumentStore {
  String? document;

  @override
  Future<String?> read() async => document;

  @override
  Future<void> write(String document) async {
    this.document = document;
  }
}

final class _RecordingCourseCatalog implements CourseCatalog {
  const _RecordingCourseCatalog(this.events);

  final List<String> events;

  @override
  Future<List<Course>> loadCourses() async {
    events.add('catalog');
    return const _FakeCourseCatalog().loadCourses();
  }
}

final class _RecordingProgressRepository implements ProgressRepository {
  const _RecordingProgressRepository(this.events);

  final List<String> events;

  @override
  Future<StudentProgress> load() async {
    events.add('progress');
    return const StudentProgress();
  }

  @override
  Future<void> save(StudentProgress progress) async {}
}

final class _CountingProgressRepository implements ProgressRepository {
  StudentProgress progress = const StudentProgress();
  int saveCount = 0;

  @override
  Future<StudentProgress> load() async => progress;

  @override
  Future<void> save(StudentProgress progress) async {
    this.progress = progress;
    saveCount++;
  }
}

final class _FakeCourseCatalog implements CourseCatalog {
  const _FakeCourseCatalog();

  @override
  Future<List<Course>> loadCourses() async => const [
    Course(
      id: 'course-1',
      title: 'Curso demo',
      version: '0.1.0',
      isDemo: true,
      modules: [
        CourseModule(
          id: 'module-1',
          title: 'Módulo demo',
          lessons: [
            Lesson(
              id: 'lesson-1',
              title: 'Lição demo',
              exercises: [
                Exercise(
                  id: 'exercise-1',
                  title: 'Tecla F',
                  type: ExerciseType.key,
                  prompt: 'Encontre a tecla F.',
                  expectedInput: 'f',
                ),
              ],
              accuracy: 90,
              secChar: 15,
            ),
          ],
        ),
      ],
    ),
  ];
}

final class _FailingCourseCatalog implements CourseCatalog {
  const _FailingCourseCatalog();

  @override
  Future<List<Course>> loadCourses() =>
      Future.error(StateError('fixture inválida'));
}

final class _FailingWriteRepository implements ProgressRepository {
  bool fail = true;
  @override
  Future<StudentProgress> load() async => const StudentProgress();
  @override
  Future<void> save(StudentProgress progress) async {
    if (fail) throw StateError('I/O indisponível');
  }
}

StudentProgress _legacyProgress({bool failed = false}) => StudentProgress(
  courses: {
    'course-1': CourseProgress(
      completedEventIds: const {'previous-event'},
      unlockedRewardIds: const {'previous-reward'},
      lessons: {
        'm1-7a-prova-codigo': LessonProgress(
          completedExerciseIds: const {'code', 'obsolete'},
          stars: 3,
          tries: 2,
          exerciseAccuracies: {'code': failed ? 0 : 100, 'obsolete': 100},
          exerciseStatistics: {
            'code': ExerciseStatistics(
              totalInputs: 90,
              correctInputs: failed ? 0 : 90,
            ),
            'obsolete': const ExerciseStatistics(
              totalInputs: 20,
              correctInputs: 20,
            ),
          },
        ),
        'm1-7b-prova-mensagens': LessonProgress(
          completedExerciseIds: const {'words'},
          stars: 3,
          tries: 3,
          exerciseAccuracies: {'words': failed ? 0 : 90},
          exerciseStatistics: {
            'words': ExerciseStatistics(
              totalInputs: 10,
              correctInputs: failed ? 0 : 9,
            ),
          },
        ),
        // Old space confirmation must never imply the new ceremony or rewards.
        'm1-8-cerimonia': const LessonProgress(
          completedExerciseIds: {'m1c9-confirmacao'},
          stars: 3,
        ),
      },
    ),
  },
);

final class _AliasCourseCatalog implements CourseCatalog {
  const _AliasCourseCatalog();
  @override
  Future<List<Course>> loadCourses() async => const [
    Course(
      id: 'course-1',
      title: 'Curso',
      version: '1',
      isDemo: true,
      modules: [
        CourseModule(
          id: 'module',
          title: 'Módulo',
          lessons: [
            Lesson(
              id: 'unified',
              title: 'Prova',
              accuracy: 90,
              legacyLessonIds: ['m1-7a-prova-codigo', 'm1-7b-prova-mensagens'],
              exercises: [
                Exercise(
                  id: 'code',
                  title: 'Código',
                  type: ExerciseType.keySequence,
                  prompt: 'Digite.',
                  expectedInput: 'fj',
                ),
                Exercise(
                  id: 'words',
                  title: 'Mensagem',
                  type: ExerciseType.phrase,
                  prompt: 'Digite.',
                  expectedInput: 'a fala',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

final class _AliasFailingWriteRepository implements ProgressRepository {
  @override
  Future<StudentProgress> load() async => _legacyProgress();
  @override
  Future<void> save(StudentProgress progress) async =>
      throw StateError('I/O indisponível');
}
