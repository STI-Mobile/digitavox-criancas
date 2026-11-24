import 'dart:async';

import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter/material.dart';

import 'design_system/components/dvx_game_components.dart';
import 'design_system/tokens/dvx_tokens.dart';
import 'keyboard_navigation.dart';

final class LessonCompletionScreen extends StatefulWidget {
  const LessonCompletionScreen({
    required this.earnedStars,
    required this.averageAccuracy,
    required this.tries,
    required this.exerciseStatistics,
    required this.onContinue,
    required this.onNarrate,
    this.actionLabel = 'Próxima missão',
    this.message = 'Muito bem! Você concluiu a missão.',
    this.character,
    this.diary,
    this.onBack,
    this.onDiaryNarration,
    super.key,
  });

  final int earnedStars;
  final double averageAccuracy;
  final int tries;
  final List<({String title, int accuracyPercent})> exerciseStatistics;
  final Future<void> Function() onContinue;
  final Future<void> Function(String text) onNarrate;
  final String actionLabel;
  final String message;
  final CourseCharacter? character;
  final String? diary;
  final VoidCallback? onBack;
  final Future<void> Function()? onDiaryNarration;

  @override
  State<LessonCompletionScreen> createState() => _LessonCompletionScreenState();
}

final class _LessonCompletionScreenState extends State<LessonCompletionScreen> {
  bool _isContinuing = false;
  final _continueFocusNode = FocusNode(debugLabel: 'continuar missão');

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

  String get _diary =>
      widget.diary ??
      [
        'Relatório de voo.',
        'Precisão média: ${widget.averageAccuracy.toStringAsFixed(1)}%.',
        '${widget.tries} ${widget.tries == 1 ? 'tentativa' : 'tentativas'} na missão.',
        for (final exercise in widget.exerciseStatistics)
          '${exercise.title}: ${exercise.accuracyPercent}%.',
      ].join(' ');

  Future<void> _openDiary() async {
    unawaited(widget.onDiaryNarration?.call() ?? widget.onNarrate(_diary));
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diário de bordo'),
        content: SingleChildScrollView(child: Text(_diary)),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar diário'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Missão concluída!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: DvxSpacing.md),
            DvxGameCard(
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: DvxSpacing.md),
            Semantics(
              container: true,
              label: 'Você ganhou ${widget.earnedStars} de 3 estrelas.',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var star = 1; star <= 3; star++)
                      Icon(
                        star <= widget.earnedStars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: context.dvxTokens.accent,
                        size: 36,
                      ),
                  ],
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
            const SizedBox(height: DvxSpacing.sm),
            KeyboardNavigationLabel(
              label: 'Ouvir diário de bordo',
              child: OutlinedButton.icon(
                onPressed: _openDiary,
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('Ouvir diário de bordo'),
              ),
            ),
            if (widget.onBack != null)
              KeyboardNavigationLabel(
                label: 'Voltar ao módulo',
                child: TextButton(
                  onPressed: widget.onBack,
                  child: const Text('Voltar ao módulo'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
