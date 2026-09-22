import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:digitavox_criancas/src/domain/exercise/key_exercise_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = KeyExerciseEvaluator();
  const exercise = Exercise(
    id: 'key-a',
    title: 'Tecla A',
    type: ExerciseType.key,
    prompt: 'Pressione A.',
    expectedInput: 'a',
  );

  test('accepts the expected key regardless of letter case', () {
    expect(
      evaluator.evaluate(exercise: exercise, input: 'A'),
      KeyExerciseEvaluation.correct,
    );
  });

  test('marks another printable key as incorrect', () {
    expect(
      evaluator.evaluate(exercise: exercise, input: 'x'),
      KeyExerciseEvaluation.incorrect,
    );
  });

  test('ignores absent, control, or multi-character input', () {
    expect(
      evaluator.evaluate(exercise: exercise, input: null),
      KeyExerciseEvaluation.ignored,
    );
    expect(
      evaluator.evaluate(exercise: exercise, input: 'ab'),
      KeyExerciseEvaluation.ignored,
    );
    expect(
      evaluator.evaluate(exercise: exercise, input: '\n'),
      KeyExerciseEvaluation.ignored,
    );
  });
}
