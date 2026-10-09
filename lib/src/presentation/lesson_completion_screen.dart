import 'dart:async';

import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter/material.dart';

final class LessonCompletionScreen extends StatefulWidget {
  const LessonCompletionScreen({
    required this.earnedStars,
    required this.averageAccuracy,
    required this.tries,
    required this.exerciseStatistics,
    required this.onContinue,
    required this.onNarrate,
    this.actionLabel = 'Próxima lição',
    this.message = 'Muito bem! Você concluiu a lição.',
    this.character,
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

  @override
  State<LessonCompletionScreen> createState() => _LessonCompletionScreenState();
}

final class _LessonCompletionScreenState extends State<LessonCompletionScreen> {
  bool _isContinuing = false;

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
  void initState() {
    super.initState();
    _narrateMessage();
  }

  @override
  void didUpdateWidget(covariant LessonCompletionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) _narrateMessage();
  }

  void _narrateMessage() {
    unawaited(widget.onNarrate(widget.message));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = widget.character;
    final averageText = widget.averageAccuracy % 1 == 0
        ? widget.averageAccuracy.toStringAsFixed(0)
        : widget.averageAccuracy.toStringAsFixed(1);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lição concluída!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    image: true,
                    label: [character?.name, character?.imageDescription]
                        .whereType<String>()
                        .where((text) => text.isNotEmpty)
                        .join('. '),
                    child: ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: character == null
                            ? Icon(
                                Icons.face_rounded,
                                size: 56,
                                color: theme.colorScheme.onSecondaryContainer,
                              )
                            : ClipOval(
                                child: Image.asset(
                                  character.imageAsset,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label:
                          '${character?.name ?? 'Seu guia'} diz: ${widget.message}',
                      child: ExcludeSemantics(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: -12,
                              top: 24,
                              child: CustomPaint(
                                size: const Size(14, 24),
                                painter: _SpeechBubbleTailPainter(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.message,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Semantics(
                container: true,
                liveRegion: true,
                label: 'Você ganhou ${widget.earnedStars} de 3 estrelas.',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        children: [
                          for (var star = 1; star <= 3; star++)
                            Icon(
                              star <= widget.earnedStars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: theme.colorScheme.primary,
                              size: 36,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'Estatísticas da lição',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text('Precisão média: $averageText%'),
              Text(
                '${widget.tries} '
                '${widget.tries == 1 ? 'tentativa' : 'tentativas'} na lição',
              ),
              
              for (final exercise in widget.exerciseStatistics)
                Text('${exercise.title}: ${exercise.accuracyPercent}%'),
              const SizedBox(height: 24),
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

final class _SpeechBubbleTailPainter extends CustomPainter {
  const _SpeechBubbleTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SpeechBubbleTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
