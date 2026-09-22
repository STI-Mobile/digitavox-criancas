import 'package:digitavox_criancas/src/application/course_catalog_view_model.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
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
