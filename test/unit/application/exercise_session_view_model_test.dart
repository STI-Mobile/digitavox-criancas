import 'package:digitavox_criancas/src/application/exercise_session_view_model.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'records an incorrect key and advances to the next expected position',
    () async {
      var completions = 0;
      final evaluations = <bool>[];
      final viewModel = _session(
        exercise: _sequence,
        onCompleted: () async => completions++,
        onInputEvaluated: (correct) async => evaluations.add(correct),
      );
      addTearDown(viewModel.dispose);

      await viewModel.handleInput('x');

      expect(viewModel.status, ExerciseSessionStatus.incorrectAnswer);
      expect(viewModel.lastExpectedInput, 'a');
      expect(viewModel.expectedCharacter, 'b');
      expect(viewModel.typedInput, 'x');
      expect(viewModel.announcement, contains('Continue com b'));
      expect(evaluations, <bool>[false]);
      expect(completions, 0);

      await viewModel.handleInput('b');
      expect(viewModel.status, ExerciseSessionStatus.completed);
      expect(viewModel.accuracyPercent, 50);
      expect(evaluations, <bool>[false, true]);
      expect(completions, 1);
    },
  );

  test('gives contextual help after four consecutive errors', () async {
    final viewModel = _session(
      exercise: const Exercise(
        id: 'sequence',
        title: 'Sequência',
        type: ExerciseType.keySequence,
        prompt: 'Digite abcde.',
        expectedInput: 'abcde',
      ),
    );
    addTearDown(viewModel.dispose);

    for (var index = 0; index < 4; index++) {
      await viewModel.handleInput('x');
    }

    expect(viewModel.consecutiveErrors, 4);
    expect(viewModel.expectedCharacter, 'e');
    expect(viewModel.announcement, startsWith('Excesso de erros'));
    expect(viewModel.announcement, contains('seta para direita'));
    expect(viewModel.announcement, contains('F1'));
  });

  test('cycles through the repetitions before completing once', () async {
    var completions = 0;
    final viewModel = _session(
      exercise: const Exercise(
        id: 'key-a',
        title: 'Tecla A',
        type: ExerciseType.key,
        prompt: 'Pressione A.',
        expectedInput: 'a',
        minimumRepetitions: 3,
      ),
      onCompleted: () async => completions++,
    );
    addTearDown(viewModel.dispose);

    await viewModel.handleInput('a');
    expect(viewModel.currentRepetition, 2);
    expect(viewModel.status, ExerciseSessionStatus.correctAnswer);
    await viewModel.handleInput('A');
    expect(viewModel.currentRepetition, 3);
    await viewModel.handleInput('a');
    await viewModel.handleInput('a');

    expect(viewModel.status, ExerciseSessionStatus.completed);
    expect(viewModel.correctInputs, 3);
    expect(completions, 1);
  });

  test('ignores absent, control and multi-character input', () async {
    var notifications = 0;
    final viewModel = _session()..addListener(() => notifications++);
    addTearDown(viewModel.dispose);

    await viewModel.handleInput(null);
    await viewModel.handleInput('\n');
    await viewModel.handleInput('ab');

    expect(viewModel.status, ExerciseSessionStatus.waitingForInput);
    expect(viewModel.lastInput, isNull);
    expect(notifications, 0);
  });

  test('exposes the reference exercise information shortcuts', () async {
    final fixedNow = DateTime(2026, 9, 24, 14, 5);
    final viewModel = _session(exercise: _sequence, now: () => fixedNow);
    addTearDown(viewModel.dispose);

    await viewModel.handleShortcut(ExerciseShortcut.help);
    expect(viewModel.helpVisible, isTrue);
    await viewModel.handleShortcut(ExerciseShortcut.nextKey);
    expect(viewModel.announcement, 'Próxima tecla: a.');
    await viewModel.handleShortcut(ExerciseShortcut.spellRemaining);
    expect(viewModel.announcement, 'Restante: a, b.');
    await viewModel.handleShortcut(ExerciseShortcut.remaining);
    expect(viewModel.announcement, 'Restante do exercício: ab.');
    await viewModel.handleShortcut(
      ExerciseShortcut.lessonPresentation,
      lessonPresentation: 'Apresentação da lição.',
    );
    expect(viewModel.announcement, 'Apresentação da lição.');
    await viewModel.handleShortcut(ExerciseShortcut.currentTime);
    expect(viewModel.announcement, 'Hora atual: 14 e 05.');
  });

  test('reports input evaluation without knowing audio details', () async {
    final evaluations = <bool>[];
    final viewModel = _session(
      onInputEvaluated: (correct) async => evaluations.add(correct),
    );
    addTearDown(viewModel.dispose);

    await viewModel.handleInput('x');
    await viewModel.handleInput('a');

    expect(viewModel.status, ExerciseSessionStatus.completed);
    expect(evaluations, <bool>[false]);
  });
}

const _exercise = Exercise(
  id: 'key-a',
  title: 'Tecla A',
  type: ExerciseType.key,
  prompt: 'Pressione A.',
  expectedInput: 'a',
);

const _sequence = Exercise(
  id: 'sequence-ab',
  title: 'Sequência AB',
  type: ExerciseType.keySequence,
  prompt: 'Digite A e B.',
  expectedInput: 'ab',
);

ExerciseSessionViewModel _session({
  Exercise exercise = _exercise,
  Future<void> Function()? onCompleted,
  Future<void> Function(bool correct)? onInputEvaluated,
  DateTime Function()? now,
}) => ExerciseSessionViewModel(
  exercise: exercise,
  onCompleted: onCompleted ?? () async {},
  onInputEvaluated: onInputEvaluated ?? (_) async {},
  now: now,
);
