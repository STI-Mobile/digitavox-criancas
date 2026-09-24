import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/course_journey_engine.dart';
import '../application/exercise_session_view_model.dart';
import '../infrastructure/input/physical_keyboard_input_interpreter.dart';

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
        final expected = _viewModel.exercise.expectedInput!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label:
                  '${_viewModel.exercise.prompt} '
                  'Exercício: $expected. '
                  'Próxima tecla: ${_viewModel.expectedCharacter}.',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Text(
                      _viewModel.exercise.prompt,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      expected.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: expected.runes.length == 1 ? 96 : 42,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_viewModel.totalRepetitions > 1)
              Text(
                'Repetição ${_viewModel.currentRepetition} de ${_viewModel.totalRepetitions}',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            _ExerciseFeedback(
              status: _viewModel.status,
              announcement: _viewModel.announcement,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
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

final class _ExerciseFeedback extends StatelessWidget {
  const _ExerciseFeedback({required this.status, required this.announcement});

  final ExerciseSessionStatus status;
  final String? announcement;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      ExerciseSessionStatus.waitingForInput => Icons.keyboard,
      ExerciseSessionStatus.incorrectAnswer => Icons.error_outline,
      ExerciseSessionStatus.correctAnswer => Icons.check_circle_outline,
      ExerciseSessionStatus.completed => Icons.celebration_outlined,
    };
    final message = announcement ?? 'Digite a próxima tecla do exercício.';
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
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
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atalhos do exercício',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(item),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
