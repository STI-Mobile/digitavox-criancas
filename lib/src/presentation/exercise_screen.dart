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
    if (_viewModel.status == ExerciseSessionStatus.completed) {
      return KeyEventResult.ignored;
    }
    final input = _inputInterpreter.interpret(event);
    if (event is KeyDownEvent) {
      unawaited(_viewModel.handleInput(input));
    }
    return input == null ? KeyEventResult.ignored : KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final expectedInput = _viewModel.exercise.expectedInput!.toUpperCase();
    final next = widget.engine.nextTarget;

    return Focus(
      autofocus: true,
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Semantics(
            header: true,
            label:
                '${_viewModel.exercise.prompt} '
                'A tecla esperada é $expectedInput.',
            child: ExcludeSemantics(
              child: Column(
                children: [
                  const Text('Pressione', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 8),
                  Text(
                    expectedInput,
                    style: const TextStyle(
                      fontSize: 112,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ExerciseFeedback(
            status: _viewModel.status,
            expectedInput: expectedInput,
            lastInput: _viewModel.lastInput,
          ),
          const SizedBox(height: 24),
          if (_viewModel.status != ExerciseSessionStatus.completed)
            Center(
              child: IconButton.outlined(
                onPressed: _keyboardFocusNode.requestFocus,
                tooltip: 'Ativar entrada pelo teclado físico',
                icon: const Icon(Icons.keyboard),
              ),
            ),
          if (_viewModel.status == ExerciseSessionStatus.completed)
            ElevatedButton(
              onPressed: widget.engine.continueAfterExercise,
              child: Text(
                next == null
                    ? 'Voltar à lição'
                    : identical(next.lesson, widget.engine.lesson)
                    ? 'Próximo exercício: ${next.exercise.title}'
                    : 'Próxima lição: ${next.lesson.title}',
              ),
            ),
        ],
      ),
    );
  }
}

final class _ExerciseFeedback extends StatelessWidget {
  const _ExerciseFeedback({
    required this.status,
    required this.expectedInput,
    required this.lastInput,
  });

  final ExerciseSessionStatus status;
  final String expectedInput;
  final String? lastInput;

  @override
  Widget build(BuildContext context) {
    final (icon, message, semanticMessage) = switch (status) {
      ExerciseSessionStatus.waitingForInput => (
        Icons.keyboard,
        'Aguardando',
        'Aguardando entrada. Pressione a tecla $expectedInput.',
      ),
      ExerciseSessionStatus.incorrectAnswer => (
        Icons.replay,
        'Tente novamente',
        'Tecla ${lastInput?.toUpperCase()} incorreta. Tente novamente. '
            'A tecla esperada é $expectedInput.',
      ),
      ExerciseSessionStatus.correctAnswer => (
        Icons.check_circle_outline,
        'Certo',
        'Resposta correta.',
      ),
      ExerciseSessionStatus.completed => (
        Icons.celebration_outlined,
        'Concluído',
        'Resposta correta. Exercício concluído.',
      ),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticMessage,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
