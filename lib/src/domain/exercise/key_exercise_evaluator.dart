import '../content/course_catalog.dart';

enum KeyExerciseEvaluation { correct, incorrect, ignored }

final class KeyExerciseEvaluator {
  const KeyExerciseEvaluator();

  KeyExerciseEvaluation evaluate({
    required Exercise exercise,
    required String? input,
  }) {
    if (exercise.type != ExerciseType.key || exercise.expectedInput == null) {
      throw ArgumentError.value(
        exercise.type,
        'exercise',
        'deve ser um exercício de tecla com entrada esperada',
      );
    }
    if (input == null || !_isSinglePrintableCharacter(input)) {
      return KeyExerciseEvaluation.ignored;
    }

    return input.toLowerCase() == exercise.expectedInput!.toLowerCase()
        ? KeyExerciseEvaluation.correct
        : KeyExerciseEvaluation.incorrect;
  }
}

bool _isSinglePrintableCharacter(String value) {
  if (value.runes.length != 1) {
    return false;
  }
  final codePoint = value.runes.single;
  return codePoint >= 0x20 && codePoint != 0x7f;
}
