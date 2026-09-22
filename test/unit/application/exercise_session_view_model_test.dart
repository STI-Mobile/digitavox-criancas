import 'dart:async';

import 'package:digitavox_criancas/src/application/exercise_session_view_model.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the exercise open after an incorrect key', () async {
    var completions = 0;
    final viewModel = ExerciseSessionViewModel(
      exercise: _exercise,
      onCompleted: () async {
        completions++;
      },
    );
    addTearDown(viewModel.dispose);

    await viewModel.handleInput('x');

    expect(viewModel.status, ExerciseSessionStatus.incorrectAnswer);
    expect(viewModel.lastInput, 'x');
    expect(completions, 0);
  });

  test('ignores input that does not represent one key', () async {
    var notifications = 0;
    final viewModel = ExerciseSessionViewModel(
      exercise: _exercise,
      onCompleted: () async {},
    )..addListener(() => notifications++);
    addTearDown(viewModel.dispose);

    await viewModel.handleInput(null);
    await viewModel.handleInput('ab');

    expect(viewModel.status, ExerciseSessionStatus.waitingForInput);
    expect(viewModel.lastInput, isNull);
    expect(notifications, 0);
  });

  test('transitions through correct answer and completes only once', () async {
    final persistence = Completer<void>();
    var completions = 0;
    final transitions = <ExerciseSessionStatus>[];
    final viewModel = ExerciseSessionViewModel(
      exercise: _exercise,
      onCompleted: () {
        completions++;
        return persistence.future;
      },
    );
    viewModel.addListener(() => transitions.add(viewModel.status));
    addTearDown(viewModel.dispose);

    final completion = viewModel.handleInput('A');

    expect(viewModel.status, ExerciseSessionStatus.correctAnswer);
    expect(completions, 1);

    persistence.complete();
    await completion;
    await viewModel.handleInput('a');

    expect(viewModel.status, ExerciseSessionStatus.completed);
    expect(completions, 1);
    expect(transitions, [
      ExerciseSessionStatus.correctAnswer,
      ExerciseSessionStatus.completed,
    ]);
  });
}

const _exercise = Exercise(
  id: 'key-a',
  title: 'Tecla A',
  type: ExerciseType.key,
  prompt: 'Pressione A.',
  expectedInput: 'a',
);
