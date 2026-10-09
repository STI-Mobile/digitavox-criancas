import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/course_journey_engine.dart';
import '../application/exercise_session_view_model.dart';
import '../infrastructure/input/physical_keyboard_input_interpreter.dart';
import 'design_system/components/dvx_game_components.dart';
import 'design_system/tokens/dvx_tokens.dart';
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

  @override
  void initState() {
    super.initState();
    _viewModel = widget.engine.session!;
    _keyboardFocusNode = FocusNode(debugLabel: 'entrada do exercício');
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final shortcut = _shortcutFor(event);
    if (shortcut != null) {
      unawaited(_handleShortcut(shortcut));
      return KeyEventResult.handled;
    }
    final input = _inputInterpreter.interpret(event);
    if (input == null) return KeyEventResult.ignored;
    unawaited(_viewModel.handleInput(input));
    return KeyEventResult.handled;
  }

  Future<void> _handleShortcut(ExerciseShortcut shortcut) async {
    await _viewModel.handleShortcut(
      shortcut,
      lessonPresentation: widget.engine.lesson?.scene?.text,
      lessonInstruction: _viewModel.exercise.prompt,
    );
    if (!mounted) return;
    if (shortcut == ExerciseShortcut.repeatExercise) {
      await widget.engine.replayNarration();
    }
  }

  ExerciseShortcut? _shortcutFor(KeyDownEvent event) {
    final key = event.logicalKey;
    final control = HardwareKeyboard.instance.isControlPressed;
    if (key == LogicalKeyboardKey.f1) return ExerciseShortcut.help;
    if (key == LogicalKeyboardKey.f2 ||
        (key == LogicalKeyboardKey.arrowDown && !control)) {
      return ExerciseShortcut.nextKey;
    }
    if (key == LogicalKeyboardKey.f3 ||
        (key == LogicalKeyboardKey.arrowRight && control)) {
      return ExerciseShortcut.spellRemaining;
    }
    if (key == LogicalKeyboardKey.f4 ||
        (key == LogicalKeyboardKey.arrowRight && !control)) {
      return ExerciseShortcut.remaining;
    }
    if (key == LogicalKeyboardKey.f5 ||
        (key == LogicalKeyboardKey.arrowUp && !control)) {
      return ExerciseShortcut.repeatExercise;
    }
    if (key == LogicalKeyboardKey.f6 ||
        (key == LogicalKeyboardKey.arrowUp && control)) {
      return ExerciseShortcut.lessonPresentation;
    }
    if (key == LogicalKeyboardKey.f7 ||
        (key == LogicalKeyboardKey.arrowDown && control)) {
      return ExerciseShortcut.lessonInstruction;
    }
    if (key == LogicalKeyboardKey.f8) return ExerciseShortcut.currentTime;
    if (key == LogicalKeyboardKey.f9) return ExerciseShortcut.statistics;
    if (key == LogicalKeyboardKey.arrowLeft) {
      return control ? ExerciseShortcut.accuracy : ExerciseShortcut.repetition;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    focusNode: _keyboardFocusNode,
    onKeyEvent: _handleKeyEvent,
    child: AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.status == ExerciseSessionStatus.completed) {
          if (widget.engine.currentLessonCompleted) {
            final hasNextLesson = widget.engine.nextTarget != null;
            return LessonCompletionScreen(
              earnedStars: widget.engine.currentLessonStars,
              averageAccuracy: widget.engine.currentLessonAverageAccuracy,
              tries: widget.engine.currentLessonTries,
              exerciseStatistics: widget.engine.currentLessonExerciseStatistics,
              actionLabel: hasNextLesson ? 'Próxima lição' : 'Voltar à lição',
              message:
                  'Muito bem! Você concluiu a lição '
                  '${widget.engine.lesson!.title}.',
              onContinue: () async {
                widget.engine.continueAfterExercise();
              },
              character: widget.engine.character,
              onNarrate: widget.engine.courseAudio.speakText,
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
            onNarrate: widget.engine.courseAudio.speakText,
          );
        }

        final expected = _viewModel.exercise.expectedInput!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                _viewModel.exercise.prompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: DvxSpacing.md),
            DvxKeyPrompt(
              value: expected,
              nextCharacter: _viewModel.expectedCharacter,
            ),
            const SizedBox(height: DvxSpacing.md),
            if (_viewModel.totalRepetitions > 1)
              DvxGameCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: DvxSpacing.md,
                  vertical: DvxSpacing.sm,
                ),
                child: Text(
                  'Repetição ${_viewModel.currentRepetition} de ${_viewModel.totalRepetitions}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            const SizedBox(height: DvxSpacing.sm),
            Text(
              _viewModel.typedInput.isEmpty
                  ? 'Aguardando entrada'
                  : 'Digitado: ${_viewModel.typedInput}',
              textAlign: TextAlign.center,
            ),
            Text(
              _viewModel.hasPendingInput
                  ? 'Próxima tecla: ${_viewModel.expectedCharacter.toUpperCase()}'
                  : 'Finalizando exercício',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DvxSpacing.md),
            DvxFeedback(
              kind: switch (_viewModel.status) {
                ExerciseSessionStatus.waitingForInput =>
                  DvxFeedbackKind.waiting,
                ExerciseSessionStatus.correctAnswer => DvxFeedbackKind.success,
                ExerciseSessionStatus.incorrectAnswer => DvxFeedbackKind.error,
                ExerciseSessionStatus.completed => DvxFeedbackKind.completed,
              },
              message:
                  _viewModel.announcement ??
                  'Digite a próxima tecla do exercício.',
            ),
            const SizedBox(height: DvxSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: DvxSpacing.sm,
              runSpacing: DvxSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _keyboardFocusNode.requestFocus,
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Ativar teclado'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleShortcut(ExerciseShortcut.help),
                  icon: const Icon(Icons.help_outline),
                  label: Text(
                    _viewModel.helpVisible ? 'Fechar atalhos' : 'Atalhos F1',
                  ),
                ),
              ],
            ),
            if (_viewModel.helpVisible) const _ExerciseShortcutHelp(),
          ],
        );
      },
    ),
  );
}

final class _ExerciseOutcome extends StatefulWidget {
  const _ExerciseOutcome({
    required this.message,
    required this.actionLabel,
    required this.onContinue,
    required this.onNarrate,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onContinue;
  final Future<void> Function(String text) onNarrate;

  @override
  State<_ExerciseOutcome> createState() => _ExerciseOutcomeState();
}

final class _ExerciseOutcomeState extends State<_ExerciseOutcome> {
  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();
    _narrateMessage();
  }

  @override
  void didUpdateWidget(covariant _ExerciseOutcome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) _narrateMessage();
  }

  void _narrateMessage() {
    unawaited(widget.onNarrate(widget.message));
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
                  'Exercício concluído!',
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
              FilledButton.icon(
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
            ],
          ),
        ),
      ),
    );
  }
}

final class _ExerciseShortcutHelp extends StatelessWidget {
  const _ExerciseShortcutHelp();

  static const items = [
    'F1 — abrir ou fechar esta ajuda',
    'F2 ou seta para baixo — próxima tecla',
    'F3 ou Control + seta para direita — soletrar o restante',
    'F4 ou seta para direita — informar o restante',
    'F5 ou seta para cima — repetir o exercício',
    'F6 ou Control + seta para cima — apresentação da lição',
    'F7 ou Control + seta para baixo — instrução da lição',
    'F8 — hora atual',
    'F9 — tempo e percentual de acertos',
    'Seta para esquerda — repetição atual',
    'Control + seta para esquerda — percentual de acertos',
    'Escape — voltar',
  ];

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: items.join('. '),
    child: ExcludeSemantics(
      child: Card(
        margin: const EdgeInsets.only(top: DvxSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(DvxSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atalhos do exercício',
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
    ),
  );
}
