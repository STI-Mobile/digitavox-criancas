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

/// A text practice consumes one position per keystroke, including mistakes.
/// Course data supplies the sequences, separators, assistance and time budget.
final class ExerciseSessionViewModel extends ChangeNotifier {
  ExerciseSessionViewModel({
    required this.exercise,
    required this.onCompleted,
    required this.onInputEvaluated,
    required this.onAttemptStarted,
    this.practice = const CoursePracticeConfiguration(),
    this.timeLimitSeconds,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _expectedCharacters = exercise.inputForRepetition(1).runes.toList() {
    if (_expectedCharacters.isEmpty) {
      throw ArgumentError.value(
        exercise.expectedInput,
        'exercise',
        'deve possuir uma entrada esperada',
      );
    }
  }

  final Exercise exercise;
  final CoursePracticeConfiguration practice;
  final int? timeLimitSeconds;
  final Future<void> Function(int accuracyPercent) onCompleted;
  final Future<void> Function(bool correct) onInputEvaluated;
  final Future<int> Function() onAttemptStarted;
  final DateTime Function() _now;
  List<int> _expectedCharacters;
  Duration _accumulatedTime = Duration.zero;
  DateTime? _activeSince;
  Timer? _timeCheck;

  ExerciseSessionStatus _status = ExerciseSessionStatus.waitingForInput;
  String? _lastInput;
  String? _lastExpectedInput;
  String? _announcement;
  String? _completionError;
  var _typedInput = '';
  var _inputIndex = 0;
  var _currentRepetition = 1;
  var _correctInputs = 0;
  var _incorrectInputs = 0;
  var _consecutiveErrors = 0;
  var _helpVisible = false;
  var _isPaused = false;
  var _pausedBeforeHelp = false;
  var _isCompleting = false;
  var _isDisposed = false;
  var _timeExpired = false;
  final Map<String, int> errorDistribution = {};
  final Map<String, int> errorPairs = {};
  Future<int>? _attemptStart;
  var _lessonTries = 0;

  ExerciseSessionStatus get status => _status;
  String? get lastInput => _lastInput;
  String? get lastExpectedInput => _lastExpectedInput;
  String? get announcement => _announcement;
  String? get completionError => _completionError;
  String get typedInput => _typedInput;
  int get inputIndex => _inputIndex;
  int get currentRepetition => _currentRepetition;
  int get totalRepetitions => exercise.minimumRepetitions ?? 1;
  int get correctInputs => _correctInputs;
  int get incorrectInputs => _incorrectInputs;
  int get totalInputs => _correctInputs + _incorrectInputs;
  int get lessonTries => _lessonTries;
  int get consecutiveErrors => _consecutiveErrors;
  bool get helpVisible => _helpVisible;
  bool get isPaused => _isPaused;
  bool get timeExpired => _timeExpired;
  bool get spellOut => exercise.spellOut;
  bool get hasPendingInput => _inputIndex < _expectedCharacters.length;
  Duration get elapsed {
    final activeSince = _activeSince;
    final active = activeSince == null
        ? Duration.zero
        : _now().difference(activeSince);
    return _accumulatedTime + (active.isNegative ? Duration.zero : active);
  }

  String get expectedCharacter => String.fromCharCode(
    _expectedCharacters[_inputIndex < _expectedCharacters.length
        ? _inputIndex
        : _expectedCharacters.length - 1],
  );

  String get nextKeyDescription {
    final finger = practice.keyFingers[expectedCharacter.toLowerCase()];
    return '${_spoken(expectedCharacter)}${finger == null ? '' : '. $finger'}';
  }

  String get remainingInput =>
      String.fromCharCodes(_expectedCharacters.skip(_inputIndex));
  int get accuracyPercent =>
      totalInputs == 0 ? 0 : ((_correctInputs * 100) / totalInputs).floor();
  double get lettersPerMinute => elapsed.inMilliseconds == 0
      ? 0
      : totalInputs * 60000 / elapsed.inMilliseconds;
  double get wordsPerMinute => lettersPerMinute / 5;

  void pause() {
    if (_isDisposed ||
        _status == ExerciseSessionStatus.completed ||
        _isPaused ||
        _isCompleting) {
      return;
    }
    _stopClock();
    _isPaused = true;
    _announcement = 'Prática pausada.';
    notifyListeners();
  }

  void resume() {
    if (_isDisposed ||
        !_isPaused ||
        _helpVisible ||
        _status == ExerciseSessionStatus.completed) {
      return;
    }
    _isPaused = false;
    if (_attemptStart != null) _startClock();
    _announcement = 'Prática retomada.';
    notifyListeners();
  }

  Future<void> handleInput(String? input) async {
    if (_isDisposed ||
        _isCompleting ||
        _isPaused ||
        _completionError != null ||
        _status == ExerciseSessionStatus.completed) {
      return;
    }
    if (input == null || !_isSinglePrintableCharacter(input)) return;
    try {
      await _ensureAttemptStarted();
    } on Object {
      if (!_isDisposed) {
        _announcement =
            'Não foi possível registrar a tentativa. Tente digitar novamente.';
        notifyListeners();
      }
      return;
    }
    if (_isDisposed ||
        _isCompleting ||
        _isPaused ||
        _status == ExerciseSessionStatus.completed) {
      return;
    }
    _startClock();
    if (await checkTimeLimit()) return;

    final expected = expectedCharacter;
    final correct = practice.caseSensitive
        ? input == expected
        : input.toLowerCase() == expected.toLowerCase();
    _lastInput = input;
    _lastExpectedInput = expected;
    _typedInput += input;
    _inputIndex++;
    if (correct) {
      _correctInputs++;
      _consecutiveErrors = 0;
      _status = ExerciseSessionStatus.correctAnswer;
      _announcement = hasPendingInput && spellOut
          ? 'Correto. Próxima tecla: ${_spoken(expectedCharacter)}.'
          : 'Correto.';
    } else {
      _incorrectInputs++;
      _consecutiveErrors++;
      errorDistribution.update(input, (count) => count + 1, ifAbsent: () => 1);
      final pair = '${_spoken(expected)} → ${_spoken(input)}';
      errorPairs.update(pair, (count) => count + 1, ifAbsent: () => 1);
      _status = ExerciseSessionStatus.incorrectAnswer;
      _announcement = hasPendingInput && spellOut
          ? 'Tecla ${_spoken(input)} incorreta. Era ${_spoken(expected)}. Continue com ${_spoken(expectedCharacter)}.'
          : 'Tecla ${_spoken(input)} incorreta. Continue a prática.';
      if (_consecutiveErrors == practice.excessiveErrorsThreshold) {
        _announcement = 'Precisa de ajuda? Pressione F1. $_announcement';
      }
    }
    final feedback = onInputEvaluated(correct);
    if (hasPendingInput) {
      notifyListeners();
      unawaited(feedback);
      return;
    }
    if (_currentRepetition < totalRepetitions) {
      _currentRepetition++;
      _inputIndex = 0;
      _typedInput = '';
      _expectedCharacters = exercise
          .inputForRepetition(_currentRepetition)
          .runes
          .toList();
      _announcement =
          '${_announcement ?? ''} Repetição $_currentRepetition de $totalRepetitions.';
      notifyListeners();
      unawaited(feedback);
      return;
    }
    _isCompleting = true;
    _stopClock();
    notifyListeners();
    await feedback;
    await _saveCompletion();
  }

  /// Timer and input use the same deadline, so a key arriving after it cannot
  /// turn an expired attempt into an approval.
  Future<bool> checkTimeLimit() async {
    final limit = timeLimitSeconds;
    if (limit == null ||
        _isDisposed ||
        _isPaused ||
        _isCompleting ||
        _status == ExerciseSessionStatus.completed) {
      return false;
    }
    if (elapsed < Duration(seconds: limit)) return false;
    _timeExpired = true;
    _isCompleting = true;
    _stopClock();
    _announcement = 'O tempo desta prática terminou. Vamos praticar novamente.';
    notifyListeners();
    await _saveCompletion();
    return true;
  }

  Future<void> retryCompletion() async {
    if (_isDisposed || _completionError == null || _isCompleting) return;
    _isCompleting = true;
    _completionError = null;
    notifyListeners();
    await _saveCompletion();
  }

  Future<void> _saveCompletion() async {
    if (_isDisposed) return;
    try {
      await onCompleted(accuracyPercent);
      if (_isDisposed) return;
      _status = ExerciseSessionStatus.completed;
      _announcement = _timeExpired
          ? 'O tempo desta prática terminou. Vamos praticar novamente.'
          : 'Exercício concluído. Acertos: $accuracyPercent por cento.';
    } on Object {
      if (_isDisposed) return;
      _completionError =
          'Não foi possível salvar o resultado. Tente salvar novamente.';
      _announcement = _completionError;
    } finally {
      _isCompleting = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> handleShortcut(
    ExerciseShortcut shortcut, {
    String? lessonPresentation,
    String? lessonInstruction,
  }) async {
    if (_isDisposed) return;
    switch (shortcut) {
      case ExerciseShortcut.help:
        if (!_helpVisible) {
          _pausedBeforeHelp = _isPaused;
          pause();
          _helpVisible = true;
          _announcement = 'Ajuda aberta. A prática está pausada.';
        } else {
          _helpVisible = false;
          if (!_pausedBeforeHelp) resume();
          _announcement = _isPaused
              ? 'Ajuda fechada. Prática pausada.'
              : 'Ajuda fechada. Continue a prática.';
        }
      case ExerciseShortcut.repetition:
        _announcement = 'Repetição $_currentRepetition de $totalRepetitions.';
      case ExerciseShortcut.accuracy:
        _announcement = 'Acertos: $accuracyPercent por cento.';
      case ExerciseShortcut.nextKey:
        _announcement = 'Próxima tecla: $nextKeyDescription.';
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
            : 'Esta missão não possui apresentação adicional.';
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
            'Tempo decorrido: ${_formatDuration(elapsed)}. Acertos: $accuracyPercent por cento. '
            '$_correctInputs teclas corretas e $_incorrectInputs incorretas. '
            'Letras por minuto: ${lettersPerMinute.toStringAsFixed(1)}. Palavras por minuto: ${wordsPerMinute.toStringAsFixed(1)}. '
            'Trocas de teclas: ${errorDistributionString(errorPairs)}. Tentativas nesta missão: $_lessonTries.';
    }
    notifyListeners();
  }

  void _startClock() {
    if (_activeSince != null || _isPaused || _isCompleting) return;
    _activeSince = _now();
    if (timeLimitSeconds != null) {
      _timeCheck ??= Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => unawaited(checkTimeLimit()),
      );
    }
  }

  void _stopClock() {
    _accumulatedTime = elapsed;
    _activeSince = null;
    _timeCheck?.cancel();
    _timeCheck = null;
  }

  Future<void> _ensureAttemptStarted() async {
    final attemptStart = _attemptStart ??= onAttemptStarted();
    try {
      _lessonTries = await attemptStart;
    } on Object {
      if (identical(_attemptStart, attemptStart)) _attemptStart = null;
      rethrow;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopClock();
    super.dispose();
  }
}

bool _isSinglePrintableCharacter(String value) {
  if (value.runes.length != 1) return false;
  final codePoint = value.runes.single;
  return codePoint >= 0x20 && codePoint != 0x7f;
}

String _spoken(String value) => value == ' '
    ? 'barra de espaço'
    : value == 'ç'
    ? 'cê-cedilha'
    : value;
String _twoDigits(int value) => value.toString().padLeft(2, '0');
String _formatDuration(Duration duration) =>
    '${duration.inMinutes} minutos e ${duration.inSeconds.remainder(60)} segundos';
String errorDistributionString(Map<String, int> errorDistribution) =>
    errorDistribution.isEmpty
    ? 'Sem erros'
    : errorDistribution.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('; ');
