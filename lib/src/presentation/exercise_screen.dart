import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/audio/audio_coordinator.dart';
import '../application/exercise_session_view_model.dart';
import '../domain/content/course_catalog.dart';
import '../infrastructure/feedback/system_exercise_sound_feedback.dart';
import '../infrastructure/input/physical_keyboard_input_interpreter.dart';

final class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    required this.exercise,
    required this.onCompleted,
    required this.audioCoordinator,
    super.key,
  });

  final Exercise exercise;
  final Future<void> Function() onCompleted;
  final AudioCoordinator audioCoordinator;

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
    _viewModel = ExerciseSessionViewModel(
      exercise: widget.exercise,
      onCompleted: widget.onCompleted,
      soundFeedback: const SystemExerciseSoundFeedback(),
      audioCoordinator: widget.audioCoordinator,
    );
    _keyboardFocusNode = FocusNode(debugLabel: 'entrada do exercício');
    unawaited(_viewModel.start());
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final input = _inputInterpreter.interpret(event);
    if (event is KeyDownEvent) {
      unawaited(_viewModel.handleInput(input));
    }
    return input == null ? KeyEventResult.ignored : KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final expectedInput = widget.exercise.expectedInput!.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text('Tecla $expectedInput')),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  label:
                      '${widget.exercise.prompt} '
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
                    child: Semantics(
                      button: true,
                      label: 'Ativar entrada pelo teclado físico',
                      child: ExcludeSemantics(
                        child: IconButton.outlined(
                          onPressed: _keyboardFocusNode.requestFocus,
                          tooltip: 'Ativar teclado',
                          icon: const Icon(Icons.keyboard),
                        ),
                      ),
                    ),
                  ),
                if (_viewModel.status == ExerciseSessionStatus.completed)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continuar'),
                  ),
              ],
            ),
          ),
        ),
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
