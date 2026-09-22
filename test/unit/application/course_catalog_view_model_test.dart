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
    await viewModel.completeExercise(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
    );

    expect(viewModel.status, CourseCatalogStatus.ready);
    expect(viewModel.courses.single.title, 'Curso demo');
    expect(viewModel.progress.totalStars, 1);
    expect((await repository.load()).totalStars, 1);
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

    await viewModel.completeExercise(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
    );
    await viewModel.completeExercise(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
    );

    expect(viewModel.progress.totalStars, 1);
    expect(repository.saveCount, 1);
  });

  test('restores completion after recreating the application state', () async {
    final store = _MemoryDocumentStore();
    final firstSession = CourseCatalogViewModel(
      courseCatalog: const _FakeCourseCatalog(),
      progressRepository: LocalProgressRepository(store: store),
    );
    await firstSession.initialize();
    await firstSession.completeExercise(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
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
