import 'package:digitavox_criancas/src/data/persistence/local_progress_repository.dart';
import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with empty progress when no document exists', () async {
    final repository = LocalProgressRepository(store: _FakeDocumentStore());

    final progress = await repository.load();

    expect(progress.courses, isEmpty);
    expect(progress.totalStars, 0);
  });

  test('falls back safely when the document is corrupted', () async {
    final repository = LocalProgressRepository(
      store: _FakeDocumentStore(initialDocument: '{'),
    );

    final progress = await repository.load();

    expect(progress.courses, isEmpty);
  });

  test('falls back safely when the schema version is unsupported', () async {
    final repository = LocalProgressRepository(
      store: _FakeDocumentStore(
        initialDocument: '''
          {
            "schemaVersion": 99,
            "progress": {"courses": {}, "settings": {}}
          }
        ''',
      ),
    );

    final progress = await repository.load();

    expect(progress.courses, isEmpty);
  });

  test('restores a valid existing document', () async {
    final store = _FakeDocumentStore();
    final writer = LocalProgressRepository(store: store);
    final progress = const StudentProgress().completeExercise(
      courseId: 'course-1',
      lessonId: 'lesson-1',
      exerciseId: 'exercise-1',
    );
    await writer.save(progress);

    final reader = LocalProgressRepository(store: store);
    final restored = await reader.load();

    expect(restored.totalStars, 1);
    expect(
      restored.courses['course-1']!.lessons['lesson-1']!.completedExerciseIds,
      contains('exercise-1'),
    );
  });

  test('does not hide failures from the underlying storage', () async {
    final repository = LocalProgressRepository(store: _FailingDocumentStore());

    await expectLater(repository.load(), throwsStateError);
  });
}

final class _FakeDocumentStore implements ProgressDocumentStore {
  _FakeDocumentStore({String? initialDocument}) : document = initialDocument;

  String? document;

  @override
  Future<String?> read() async => document;

  @override
  Future<void> write(String document) async {
    this.document = document;
  }
}

final class _FailingDocumentStore implements ProgressDocumentStore {
  @override
  Future<String?> read() => Future<String?>.error(StateError('falha de I/O'));

  @override
  Future<void> write(String document) async {}
}
