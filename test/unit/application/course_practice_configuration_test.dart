import 'package:digitavox_criancas/src/application/exercise_session_view_model.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('executes declared repetition and final spaces without Enter', () async {
    var completions = 0;
    final session = _session(
      exercise: const Exercise(
        id: 'fj',
        title: 'F J',
        type: ExerciseType.keySequence,
        prompt: 'Digite F e J.',
        expectedInput: 'fj',
        minimumRepetitions: 2,
        repetitionSeparator: ' ',
        trailingSeparator: ' ',
      ),
      completed: (_) async => completions++,
    );
    addTearDown(session.dispose);
    for (final character in 'fj fj'.split('')) {
      await session.handleInput(character);
    }
    expect(completions, 0);
    expect(session.expectedCharacter, ' ');
    await session.handleInput(' ');
    expect(completions, 1);
    expect(session.correctInputs, 6);
    expect(session.status, ExerciseSessionStatus.completed);
  });

  test(
    'F2 describes the configured finger and preserves cedilla pronunciation',
    () async {
      final session = _session(
        practice: const CoursePracticeConfiguration(
          keyFingers: {'ç': 'Dedo mínimo direito.'},
        ),
        exercise: const Exercise(
          id: 'cedilha',
          title: 'Ç',
          type: ExerciseType.key,
          prompt: 'Digite ç.',
          expectedInput: 'ç',
        ),
      );
      addTearDown(session.dispose);
      await session.handleShortcut(ExerciseShortcut.nextKey);
      expect(session.announcement, contains('cê-cedilha'));
      expect(session.announcement, contains('Dedo mínimo direito'));
    },
  );

  test('manual pause and help exclude time and cannot consume input', () async {
    var now = DateTime(2026, 10, 13);
    final session = _session(now: () => now, limit: 10);
    addTearDown(session.dispose);
    await session.handleInput('a');
    now = now.add(const Duration(seconds: 2));
    session.pause();
    now = now.add(const Duration(minutes: 2));
    await session.handleInput('b');
    expect(session.totalInputs, 1);
    expect(session.elapsed, const Duration(seconds: 2));
    session.resume();
    await session.handleShortcut(ExerciseShortcut.help);
    now = now.add(const Duration(minutes: 2));
    await session.handleShortcut(ExerciseShortcut.help);
    expect(session.isPaused, isFalse);
    expect(session.elapsed, const Duration(seconds: 2));
    now = now.add(const Duration(seconds: 1));
    await session.handleInput('b');
    expect(session.elapsed, const Duration(seconds: 3));
  });

  test('configured deadline ends practice and ignores a late key', () async {
    var now = DateTime(2026, 10, 13);
    var completions = 0;
    final session = _session(
      now: () => now,
      limit: 1,
      completed: (_) async => completions++,
    );
    addTearDown(session.dispose);
    await session.handleInput('a');
    now = now.add(const Duration(seconds: 1));
    await session.handleInput('b');
    expect(session.timeExpired, isTrue);
    expect(session.totalInputs, 1);
    expect(completions, 1);
    await session.checkTimeLimit();
    expect(completions, 1);
  });

  test(
    'failed attempt registration leaves input untouched and retries',
    () async {
      var attempts = 0;
      final session = ExerciseSessionViewModel(
        exercise: _exercise,
        onAttemptStarted: () async {
          if (++attempts == 1) throw StateError('storage unavailable');
          return 1;
        },
        onCompleted: (_) async {},
        onInputEvaluated: (_) async {},
      );
      addTearDown(session.dispose);
      await session.handleInput('a');
      expect(session.totalInputs, 0);
      expect(session.announcement, contains('Não foi possível registrar'));
      await session.handleInput('a');
      expect(session.totalInputs, 1);
      expect(attempts, 2);
    },
  );

  test(
    'failed final save can be retried without double counting input',
    () async {
      var saves = 0;
      final session = _session(
        exercise: const Exercise(
          id: 'a',
          title: 'A',
          type: ExerciseType.key,
          prompt: 'A',
          expectedInput: 'a',
        ),
        completed: (_) async {
          if (++saves == 1) throw StateError('storage unavailable');
        },
      );
      addTearDown(session.dispose);
      await session.handleInput('a');
      expect(session.completionError, isNotNull);
      await session.handleInput('a');
      expect(session.totalInputs, 1);
      await session.retryCompletion();
      expect(session.status, ExerciseSessionStatus.completed);
      expect(saves, 2);
    },
  );
}

const _exercise = Exercise(
  id: 'abc',
  title: 'ABC',
  type: ExerciseType.keySequence,
  prompt: 'Digite abc.',
  expectedInput: 'abc',
);
ExerciseSessionViewModel _session({
  Exercise exercise = _exercise,
  CoursePracticeConfiguration practice = const CoursePracticeConfiguration(),
  DateTime Function()? now,
  int? limit,
  Future<void> Function(int)? completed,
}) => ExerciseSessionViewModel(
  exercise: exercise,
  practice: practice,
  now: now,
  timeLimitSeconds: limit,
  onCompleted: completed ?? (_) async {},
  onInputEvaluated: (_) async {},
  onAttemptStarted: () async => 1,
);
