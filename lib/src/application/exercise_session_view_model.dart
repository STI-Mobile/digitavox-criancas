import 'package:flutter/foundation.dart';

import '../domain/content/course_catalog.dart';
import '../domain/exercise/key_exercise_evaluator.dart';

enum ExerciseSessionStatus {
  waitingForInput,
  correctAnswer,
  incorrectAnswer,
  completed,
}

final class ExerciseSessionViewModel extends ChangeNotifier {
  ExerciseSessionViewModel({
    required this.exercise,
    required this.onCompleted,
    this.evaluator = const KeyExerciseEvaluator(),
  });

  final Exercise exercise;
  final Future<void> Function() onCompleted;
  final KeyExerciseEvaluator evaluator;

  ExerciseSessionStatus _status = ExerciseSessionStatus.waitingForInput;
  String? _lastInput;
  bool _isDisposed = false;

  ExerciseSessionStatus get status => _status;
  String? get lastInput => _lastInput;

  Future<void> handleInput(String? input) async {
    if (_status == ExerciseSessionStatus.correctAnswer ||
        _status == ExerciseSessionStatus.completed) {
      return;
    }

    final evaluation = evaluator.evaluate(exercise: exercise, input: input);
    if (evaluation == KeyExerciseEvaluation.ignored) {
      return;
    }

    _lastInput = input;
    if (evaluation == KeyExerciseEvaluation.incorrect) {
      _status = ExerciseSessionStatus.incorrectAnswer;
      notifyListeners();
      return;
    }

    _status = ExerciseSessionStatus.correctAnswer;
    notifyListeners();
    await onCompleted();

    if (_isDisposed) {
      return;
    }
    _status = ExerciseSessionStatus.completed;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
