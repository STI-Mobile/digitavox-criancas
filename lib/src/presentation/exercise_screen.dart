import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/exercise_session_view_model.dart';
import '../domain/content/course_catalog.dart';
import '../infrastructure/input/physical_keyboard_input_interpreter.dart';

final class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({
    required this.exercise,
    required this.onCompleted,
    super.key,
  });

  final Exercise exercise;
  final Future<void> Function() onCompleted;

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
    );
    _keyboardFocusNode = FocusNode(debugLabel: 'entrada do exercício');
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
      appBar: AppBar(title: const Text('Exercício de tecla')),
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
                Semantics(
                  header: true,
                  child: Text(
                    widget.exercise.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label:
                      '${widget.exercise.prompt} '
                      'A tecla esperada é $expectedInput.',
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.prompt,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tecla esperada: $expectedInput',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
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
                  OutlinedButton.icon(
                    onPressed: _keyboardFocusNode.requestFocus,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Ativar entrada pelo teclado físico'),
                  ),
                if (_viewModel.status == ExerciseSessionStatus.completed)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar à lição'),
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
    final (icon, message) = switch (status) {
      ExerciseSessionStatus.waitingForInput => (
        Icons.keyboard,
        'Aguardando. Pressione a tecla $expectedInput.',
      ),
      ExerciseSessionStatus.incorrectAnswer => (
        Icons.cancel_outlined,
        'Tecla ${lastInput?.toUpperCase()} incorreta. Tente novamente.',
      ),
      ExerciseSessionStatus.correctAnswer => (
        Icons.check_circle_outline,
        'Correto!',
      ),
      ExerciseSessionStatus.completed => (
        Icons.celebration_outlined,
        'Correto. Exercício concluído.',
      ),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
