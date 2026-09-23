import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/content/course_catalog.dart';
import '../domain/exercise/key_exercise_evaluator.dart';
import 'audio/audio_coordinator.dart';
import 'exercise_sound_feedback.dart';

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
    required this.soundFeedback,
    required this.audioCoordinator,
    this.evaluator = const KeyExerciseEvaluator(),
  });

  final Exercise exercise;
  final Future<void> Function() onCompleted;
  final ExerciseSoundFeedback soundFeedback;
  final AudioCoordinator audioCoordinator;
  final KeyExerciseEvaluator evaluator;

  ExerciseSessionStatus _status = ExerciseSessionStatus.waitingForInput;
  String? _lastInput;
  bool _isDisposed = false;

  ExerciseSessionStatus get status => _status;
  String? get lastInput => _lastInput;

  Future<void> start() async {
    final audio = exercise.audio;
    if (audio != null) {
      await audioCoordinator.playContent(audio);
    }
  }

  Future<void> handleInput(String? input) async {
    if (_isDisposed ||
        _status == ExerciseSessionStatus.correctAnswer ||
        _status == ExerciseSessionStatus.completed) {
      return;
    }

    final evaluation = evaluator.evaluate(exercise: exercise, input: input);
    if (evaluation == KeyExerciseEvaluation.ignored) {
      return;
    }

    unawaited(audioCoordinator.stop());
    _lastInput = input;
    if (evaluation == KeyExerciseEvaluation.incorrect) {
      _status = ExerciseSessionStatus.incorrectAnswer;
      notifyListeners();
      unawaited(soundFeedback.playIncorrect());
      return;
    }

    _status = ExerciseSessionStatus.correctAnswer;
    notifyListeners();
    unawaited(soundFeedback.playCorrect());
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
    unawaited(audioCoordinator.stop());
    super.dispose();
  }
}
