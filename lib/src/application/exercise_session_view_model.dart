import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/content/course_catalog.dart';

enum ExerciseSessionStatus {
  waitingForInput,
  correctAnswer,
  incorrectAnswer,
  completed,
}

enum ExerciseShortcut {
  help,
  repetition,
  accuracy,
  nextKey,
  spellRemaining,
  remaining,
  repeatExercise,
  lessonPresentation,
  lessonInstruction,
  currentTime,
  statistics,
}

final class ExerciseSessionViewModel extends ChangeNotifier {
  ExerciseSessionViewModel({
    required this.exercise,
    required this.onCompleted,
    required this.onInputEvaluated,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _expectedCharacters =
           exercise.expectedInput?.runes.toList() ?? const [] {
    if (_expectedCharacters.isEmpty) {
      throw ArgumentError.value(
        exercise.expectedInput,
        'exercise',
        'deve possuir uma entrada esperada',
      );
    }
    _stopwatch.start();
  }

  static const int excessiveErrorsThreshold = 4;

  final Exercise exercise;
  final Future<void> Function() onCompleted;
  final Future<void> Function(bool correct) onInputEvaluated;
  final DateTime Function() _now;
  final List<int> _expectedCharacters;
  final Stopwatch _stopwatch = Stopwatch();

  ExerciseSessionStatus _status = ExerciseSessionStatus.waitingForInput;
  String? _lastInput;
  String? _lastExpectedInput;
  String? _announcement;
  var _typedInput = '';
  var _inputIndex = 0;
  var _currentRepetition = 1;
  var _correctInputs = 0;
  var _incorrectInputs = 0;
  var _consecutiveErrors = 0;
  var _helpVisible = false;
  var _isCompleting = false;
  var _isDisposed = false;

  ExerciseSessionStatus get status => _status;
  String? get lastInput => _lastInput;
  String? get lastExpectedInput => _lastExpectedInput;
  String? get announcement => _announcement;
  String get typedInput => _typedInput;
  int get inputIndex => _inputIndex;
  int get currentRepetition => _currentRepetition;
  int get totalRepetitions => exercise.minimumRepetitions ?? 1;
  int get correctInputs => _correctInputs;
  int get incorrectInputs => _incorrectInputs;
  int get consecutiveErrors => _consecutiveErrors;
  bool get helpVisible => _helpVisible;
  bool get hasPendingInput => _inputIndex < _expectedCharacters.length;
  Duration get elapsed => _stopwatch.elapsed;

  String get expectedCharacter => String.fromCharCode(
    _expectedCharacters[_inputIndex < _expectedCharacters.length
        ? _inputIndex
        : _expectedCharacters.length - 1],
  );

  String get remainingInput =>
      String.fromCharCodes(_expectedCharacters.skip(_inputIndex));

  int get accuracyPercent {
    final total = _correctInputs + _incorrectInputs;
    return total == 0 ? 100 : (_correctInputs * 100 / total).floor();
  }

  Future<void> handleInput(String? input) async {
    if (_isDisposed ||
        _isCompleting ||
        _status == ExerciseSessionStatus.completed) {
      return;
    }
    if (input == null || !_isSinglePrintableCharacter(input)) return;

    final expected = expectedCharacter;
    final correct = input.toLowerCase() == expected.toLowerCase();
    _lastInput = input;
    _lastExpectedInput = expected;
    _typedInput += input;
    _inputIndex++;

    if (correct) {
      _correctInputs++;
      _consecutiveErrors = 0;
      _status = ExerciseSessionStatus.correctAnswer;
      _announcement = _inputIndex < _expectedCharacters.length
          ? 'Correto. Próxima tecla: ${_spoken(expectedCharacter)}.'
          : 'Correto.';
    } else {
      _incorrectInputs++;
      _consecutiveErrors++;
      _status = ExerciseSessionStatus.incorrectAnswer;
      _announcement = _inputIndex < _expectedCharacters.length
          ? 'Tecla ${_spoken(input)} incorreta. Era ${_spoken(expected)}. '
                'Continue com ${_spoken(expectedCharacter)}.'
          : 'Tecla ${_spoken(input)} incorreta. Era ${_spoken(expected)}.';
      if (_consecutiveErrors >= excessiveErrorsThreshold) {
        _announcement =
            'Excesso de erros. Pressione seta para direita '
            'para ouvir o restante ou F1 para ajuda. $_announcement';
      }
    }

    final inputFeedback = onInputEvaluated(correct);

    if (_inputIndex < _expectedCharacters.length) {
      notifyListeners();
      unawaited(inputFeedback);
      return;
    }

    if (_currentRepetition < totalRepetitions) {
      _currentRepetition++;
      _inputIndex = 0;
      _typedInput = '';
      _announcement =
          '${_announcement ?? ''} '
          'Repetição $_currentRepetition de $totalRepetitions. '
          'Próxima tecla: ${_spoken(expectedCharacter)}.';
      notifyListeners();
      unawaited(inputFeedback);
      return;
    }

    _isCompleting = true;
    notifyListeners();
    await inputFeedback;
    if (_isDisposed) return;
    await onCompleted();
    _isCompleting = false;
    if (_isDisposed) return;
    _stopwatch.stop();
    _status = ExerciseSessionStatus.completed;
    _announcement = 'Exercício concluído. Acertos: $accuracyPercent por cento.';
    notifyListeners();
  }

  Future<void> handleShortcut(
    ExerciseShortcut shortcut, {
    String? lessonPresentation,
    String? lessonInstruction,
  }) async {
    if (_isDisposed) return;

    switch (shortcut) {
      case ExerciseShortcut.help:
        _helpVisible = !_helpVisible;
        _announcement = _helpVisible
            ? 'Ajuda aberta. Use F2 até F9 ou as setas para consultar o exercício.'
            : 'Ajuda fechada.';
      case ExerciseShortcut.repetition:
        _announcement = 'Repetição $_currentRepetition de $totalRepetitions.';
      case ExerciseShortcut.accuracy:
        _announcement = 'Acertos: $accuracyPercent por cento.';
      case ExerciseShortcut.nextKey:
        _announcement = 'Próxima tecla: ${_spoken(expectedCharacter)}.';
      case ExerciseShortcut.spellRemaining:
        _announcement =
            'Restante: ${remainingInput.runes.map((rune) => _spoken(String.fromCharCode(rune))).join(', ')}.';
      case ExerciseShortcut.remaining:
        _announcement = 'Restante do exercício: $remainingInput.';
      case ExerciseShortcut.repeatExercise:
        _announcement = 'Exercício: ${exercise.expectedInput}.';
      case ExerciseShortcut.lessonPresentation:
        _announcement = lessonPresentation?.trim().isNotEmpty == true
            ? lessonPresentation
            : 'Esta lição não possui apresentação adicional.';
      case ExerciseShortcut.lessonInstruction:
        _announcement = lessonInstruction?.trim().isNotEmpty == true
            ? lessonInstruction
            : exercise.prompt;
      case ExerciseShortcut.currentTime:
        final current = _now();
        _announcement =
            'Hora atual: ${_twoDigits(current.hour)} e ${_twoDigits(current.minute)}.';
      case ExerciseShortcut.statistics:
        _announcement =
            'Tempo decorrido: ${_formatDuration(elapsed)}. '
            'Acertos: $accuracyPercent por cento. '
            '$_correctInputs teclas corretas e $_incorrectInputs incorretas.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopwatch.stop();
    super.dispose();
  }
}

bool _isSinglePrintableCharacter(String value) {
  if (value.runes.length != 1) return false;
  final codePoint = value.runes.single;
  return codePoint >= 0x20 && codePoint != 0x7f;
}

String _spoken(String value) => value == ' ' ? 'barra de espaço' : value;

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '$minutes minutos e $seconds segundos';
}
