import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/course_journey_engine.dart';
import '../application/exercise_session_view_model.dart';
import '../infrastructure/input/physical_keyboard_input_interpreter.dart';
import 'design_system/components/dvx_game_components.dart';
import 'design_system/tokens/dvx_tokens.dart';
import 'keyboard_navigation.dart';
import 'lesson_completion_screen.dart';

final class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({required this.engine, super.key});

  final CourseJourneyEngine engine;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

final class _ExerciseScreenState extends State<ExerciseScreen> {
  static const _inputInterpreter = PhysicalKeyboardInputInterpreter();

  late final ExerciseSessionViewModel _viewModel;
  late final FocusNode _keyboardFocusNode;
  final _resumeFocusNode = FocusNode(debugLabel: 'retomar prática');

  @override
  void initState() {
    super.initState();
    _viewModel = widget.engine.session!;
    _keyboardFocusNode = FocusNode(debugLabel: 'entrada do exercício');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _keyboardFocusNode.requestFocus();
      Scrollable.ensureVisible(_keyboardFocusNode.context!);
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _resumeFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_viewModel.status == ExerciseSessionStatus.completed ||
        !_keyboardFocusNode.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    if (event is KeyRepeatEvent && _shortcutFor(event) != null) {
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final shortcut = _shortcutFor(event);
    if (shortcut != null) {
      unawaited(_handleShortcut(shortcut));
      return KeyEventResult.handled;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final input = _inputInterpreter.interpret(event);
    if (input == null) return KeyEventResult.ignored;
    if (_viewModel.isPaused) return KeyEventResult.handled;
    unawaited(widget.engine.stopNarration());
    unawaited(_viewModel.handleInput(input));
    return KeyEventResult.handled;
  }

  Future<void> _handleShortcut(ExerciseShortcut shortcut) async {
    await widget.engine.stopNarration();
    await _viewModel.handleShortcut(
      shortcut,
      lessonPresentation: widget.engine.lesson?.scene?.text,
      lessonInstruction:
          widget.engine.lesson?.scene?.instruction ??
          _viewModel.exercise.prompt,
    );
    if (shortcut == ExerciseShortcut.help && !_viewModel.helpVisible) {
      if (_viewModel.isPaused) {
        _resumeFocusNode.requestFocus();
      } else {
        _keyboardFocusNode.requestFocus();
      }
    }
    if (shortcut == ExerciseShortcut.help && _viewModel.helpVisible) {
      await widget.engine.narrateHelp();
      return;
    }
    final announcement = _viewModel.announcement;
    if (announcement != null) {
      await widget.engine.courseAudio.speakText(announcement);
    }
  }

  void _pausePractice() {
    widget.engine.pausePractice();
    _resumeFocusNode.requestFocus();
  }

  void _resumePractice() {
    widget.engine.resumePractice();
    _keyboardFocusNode.requestFocus();
  }

  Map<String, String> get _shortcutActions =>
      widget.engine.course.practice.shortcuts.isEmpty
      ? const {
          'F1': 'help',
          'F2': 'nextKey',
          'F3': 'spellRemaining',
          'F4': 'remaining',
          'F5': 'lessonInstruction',
          'F6': 'lessonPresentation',
          'F7': 'repeatExercise',
          'F8': 'currentTime',
          'F9': 'statistics',
        }
      : widget.engine.course.practice.shortcuts;

  ExerciseShortcut? _shortcutFor(KeyEvent event) {
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed) {
      return null;
    }
    final control = keyboard.isControlPressed;
    final functionKeys = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.f1: 'F1',
      LogicalKeyboardKey.f2: 'F2',
      LogicalKeyboardKey.f3: 'F3',
      LogicalKeyboardKey.f4: 'F4',
      LogicalKeyboardKey.f5: 'F5',
      LogicalKeyboardKey.f6: 'F6',
      LogicalKeyboardKey.f7: 'F7',
      LogicalKeyboardKey.f8: 'F8',
      LogicalKeyboardKey.f9: 'F9',
    };
    final functionKey = functionKeys[key];
    if (functionKey != null) {
      final action = _shortcutActions[functionKey];
      for (final shortcut in ExerciseShortcut.values) {
        if (shortcut.name == action) return shortcut;
      }
      return null;
    }
    if (key == LogicalKeyboardKey.arrowDown && !control) {
      return ExerciseShortcut.nextKey;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      return control
          ? ExerciseShortcut.spellRemaining
          : ExerciseShortcut.remaining;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      return control
          ? ExerciseShortcut.lessonPresentation
          : ExerciseShortcut.repeatExercise;
    }
    if (key == LogicalKeyboardKey.arrowDown && control) {
      return ExerciseShortcut.lessonInstruction;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      return control ? ExerciseShortcut.accuracy : ExerciseShortcut.repetition;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => KeyboardNavigationLabel(
    label: 'Entrada do exercício. ${_viewModel.exercise.prompt}',
    child: Semantics(
      label: _viewModel.status == ExerciseSessionStatus.completed
          ? null
          : 'Entrada do exercício',
      hint: _viewModel.status == ExerciseSessionStatus.completed
          ? null
          : 'Digite as teclas solicitadas. Tab para acessar os controles.',
      child: Focus(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _handleKeyEvent,
        skipTraversal:
            _viewModel.status == ExerciseSessionStatus.completed ||
            _viewModel.completionError != null,
        canRequestFocus:
            _viewModel.status != ExerciseSessionStatus.completed &&
            _viewModel.completionError == null,
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            if (_viewModel.completionError != null) {
              return _ExerciseOutcome(
                title: 'Resultado aguardando salvamento',
                message: _viewModel.completionError!,
                actionLabel: 'Tentar salvar novamente',
                onContinue: _viewModel.retryCompletion,
              );
            }
            if (_viewModel.status == ExerciseSessionStatus.completed) {
              if (widget.engine.currentLessonAttemptFinished &&
                  !widget.engine.currentLessonCompleted) {
                return _ExerciseOutcome(
                  title: 'Vamos praticar mais',
                  message: _viewModel.timeExpired
                      ? 'O tempo desta prática terminou. Vamos praticar novamente.'
                      : 'Vamos praticar novamente para concluir esta missão. Você pode usar a ajuda.',
                  actionLabel: 'Praticar novamente',
                  onContinue: () async {
                    widget.engine.retryCurrentLesson();
                  },
                );
              }
              if (widget.engine.currentLessonCompleted) {
                final hasNextLesson = widget.engine.nextTarget != null;
                return LessonCompletionScreen(
                  earnedStars: widget.engine.currentLessonStars,
                  averageAccuracy: widget.engine.currentLessonAverageAccuracy,
                  tries: widget.engine.currentLessonTries,
                  exerciseStatistics:
                      widget.engine.currentLessonExerciseStatistics,
                  actionLabel: widget.engine.isModuleReadyForCompletion
                      ? 'Concluir módulo'
                      : hasNextLesson
                      ? 'Próxima missão'
                      : 'Voltar à missão',
                  message:
                      'Muito bem! Você concluiu '
                      '${widget.engine.lesson!.title}.',
                  onContinue: () async {
                    widget.engine.continueAfterExercise();
                  },
                  diary: widget.engine.currentLessonDiary,
                  onDiaryNarration: widget.engine.narrateDiary,
                  onNarrate: widget.engine.courseAudio.speakText,
                  onBack: () => widget.engine.openModule(widget.engine.module!),
                );
              }

              final message =
                  'Precisão desta atividade: ${_viewModel.accuracyPercent}%. '
                  'Continue para a próxima atividade.';
              return _ExerciseOutcome(
                message: message,
                actionLabel: 'Próximo exercício',
                onContinue: () async {
                  widget.engine.continueAfterExercise();
                },
              );
            }

            final expected = _viewModel.exercise.expectedInput!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Exercício ${widget.engine.lesson!.exercises.indexOf(widget.engine.exercise!) + 1} de ${widget.engine.lesson!.exercises.length}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: DvxSpacing.sm),
                Text(_viewModel.exercise.prompt, textAlign: TextAlign.center),
                const SizedBox(height: DvxSpacing.md),
                DvxKeyPrompt(
                  value: expected,
                  nextCharacter: _viewModel.expectedCharacter,
                ),
                const SizedBox(height: DvxSpacing.md),
                if (_viewModel.totalRepetitions > 1)
                  Text(
                    'Repetição ${_viewModel.currentRepetition} de ${_viewModel.totalRepetitions}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: DvxSpacing.md),
                DvxFeedback(
                  kind: switch (_viewModel.status) {
                    ExerciseSessionStatus.waitingForInput =>
                      DvxFeedbackKind.waiting,
                    ExerciseSessionStatus.correctAnswer =>
                      DvxFeedbackKind.success,
                    ExerciseSessionStatus.incorrectAnswer =>
                      DvxFeedbackKind.error,
                    ExerciseSessionStatus.completed =>
                      DvxFeedbackKind.completed,
                  },
                  message: _viewModel.isPaused
                      ? 'Prática pausada. O tempo está parado.'
                      : _viewModel.announcement ??
                            'Digite a próxima tecla do exercício.',
                ),
                const SizedBox(height: DvxSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: DvxSpacing.sm,
                  runSpacing: DvxSpacing.sm,
                  children: [
                    if (_viewModel.isPaused && !_viewModel.helpVisible)
                      KeyboardNavigationLabel(
                        label: 'Retomar prática',
                        child: FilledButton.icon(
                          focusNode: _resumeFocusNode,
                          onPressed: _resumePractice,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Retomar prática'),
                        ),
                      )
                    else if (!_viewModel.helpVisible)
                      KeyboardNavigationLabel(
                        label: 'Pausar prática',
                        child: OutlinedButton.icon(
                          onPressed: _pausePractice,
                          icon: const Icon(Icons.pause),
                          label: const Text('Pausar prática'),
                        ),
                      ),
                    KeyboardNavigationLabel(
                      label: _viewModel.helpVisible
                          ? 'Fechar atalhos'
                          : 'Ajuda F1',
                      child: OutlinedButton.icon(
                        onPressed: () => _handleShortcut(ExerciseShortcut.help),
                        icon: const Icon(Icons.help_outline),
                        label: Text(
                          _viewModel.helpVisible
                              ? 'Fechar atalhos'
                              : 'Ajuda F1',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_viewModel.helpVisible)
                  _ExerciseShortcutHelp(shortcuts: _shortcutActions),
                const SizedBox(height: DvxSpacing.md),
                Text(
                  'Ao sair, os exercícios concluídos ficam salvos. '
                  'Este exercício recomeça quando você voltar.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

final class _ExerciseOutcome extends StatefulWidget {
  const _ExerciseOutcome({
    this.title = 'Exercício concluído!',
    required this.message,
    required this.actionLabel,
    required this.onContinue,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onContinue;

  @override
  State<_ExerciseOutcome> createState() => _ExerciseOutcomeState();
}

final class _ExerciseOutcomeState extends State<_ExerciseOutcome> {
  bool _isContinuing = false;
  final _continueFocusNode = FocusNode(debugLabel: 'continuar exercício');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _continueFocusNode.requestFocus();
      Scrollable.ensureVisible(_continueFocusNode.context!);
    });
  }

  @override
  void dispose() {
    _continueFocusNode.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isContinuing) return;
    setState(() => _isContinuing = true);
    try {
      await widget.onContinue();
    } finally {
      if (mounted) setState(() => _isContinuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(DvxSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: DvxSpacing.md),
              Semantics(
                liveRegion: true,
                label: widget.message,
                child: ExcludeSemantics(
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: DvxSpacing.lg),
              KeyboardNavigationLabel(
                label: widget.actionLabel,
                child: FilledButton.icon(
                  focusNode: _continueFocusNode,
                  onPressed: _isContinuing ? null : _continue,
                  icon: _isContinuing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _isContinuing ? 'Carregando...' : widget.actionLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ExerciseShortcutHelp extends StatelessWidget {
  const _ExerciseShortcutHelp({required this.shortcuts});

  final Map<String, String> shortcuts;

  static const _descriptions = <String, String>{
    'help': 'abrir ou fechar esta ajuda',
    'nextKey': 'próxima letra e dedo',
    'spellRemaining': 'soletrar o restante',
    'remaining': 'informar o restante',
    'repeatExercise': 'repetir o exercício',
    'lessonPresentation': 'apresentação da missão',
    'lessonInstruction': 'instrução da missão',
    'currentTime': 'hora atual',
    'statistics': 'tempo e percentual de acertos',
    'accuracy': 'percentual de acertos',
    'repetition': 'repetição atual',
  };

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final shortcut in shortcuts.entries)
        '${shortcut.key} — ${_descriptions[shortcut.value] ?? shortcut.value}',
      'Tab — acessar os controles; Shift + Tab — controle anterior',
      'Nos controles, setas para cima e baixo — navegar',
      'Enter ou espaço — acionar o controle selecionado',
      'Escape — sair da prática e voltar à missão',
    ];
    return Semantics(
      container: true,
      label: 'Ajuda. O tempo está pausado. ${items.join('. ')}',
      child: ExcludeSemantics(
        child: DvxGameCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajuda · tempo pausado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: DvxSpacing.sm),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: DvxSpacing.sm),
                  child: Text(item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
