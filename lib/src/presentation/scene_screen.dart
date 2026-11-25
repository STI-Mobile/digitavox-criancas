import 'dart:async';

import 'package:flutter/material.dart';

import '../application/course_journey_engine.dart';
import '../domain/content/course_catalog.dart';
import 'design_system/components/dvx_game_components.dart';
import 'design_system/course_theme/course_theme.dart';
import 'keyboard_navigation.dart';

final class CharacterLine {
  const CharacterLine({
    required this.character,
    required this.text,
    required this.cues,
    this.illustrationLineId,
  });

  final CourseCharacter character;
  final String text;
  final List<ContentAudioCue> cues;
  final String? illustrationLineId;

  bool get hasSpeech =>
      cues.any((cue) => cue.type == ContentAudioCueType.speech);
}

final class SceneScreen extends StatefulWidget {
  const SceneScreen({
    required this.engine,
    required this.lines,
    required this.illustration,
    required this.onComplete,
    required this.narrationControls,
    this.continuationLabel = 'Continuar para o curso',
    this.autofocusContinue = true,
    super.key,
  }) : assert(lines.length > 0);

  final CourseJourneyEngine engine;
  final List<CharacterLine> lines;
  final CourseIllustration? illustration;
  final VoidCallback onComplete;
  final Widget Function({List<ContentAudioCue>? cues}) narrationControls;
  final String continuationLabel;
  final bool autofocusContinue;

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

final class _SceneScreenState extends State<SceneScreen> {
  var _lineIndex = 0;
  var _completed = false;

  CharacterLine get _currentLine => widget.lines[_lineIndex];

  @override
  void initState() {
    super.initState();
    unawaited(_play(_currentLine.cues));
  }

  Future<void> _play(List<ContentAudioCue> cues) async {
    await widget.engine.stopNarration();
    if (!mounted) return;
    await widget.engine.courseAudio.play(
      CourseAudioConfiguration(start: cues),
      CourseAudioEvent.start,
    );
  }

  void _continue() {
    if (_lineIndex + 1 < widget.lines.length) {
      setState(() => _lineIndex++);
      unawaited(_play(_currentLine.cues));
      return;
    }
    unawaited(widget.engine.stopNarration());
    setState(() => _completed = true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return const SizedBox.shrink();

    final spacing = context.courseTheme.spacing;
    final line = _currentLine;
    final illustration = widget.illustration;
    final illustrationLine = illustration?.lines
        .where(
          (item) =>
              item.id == line.illustrationLineId ||
              (line.illustrationLineId == null &&
                  item.characterId == line.character.id),
        )
        .firstOrNull;
    final imageAsset = illustrationLine?.imageAsset ?? illustration?.imageAsset;
    final imageDescription =
        illustrationLine?.imageDescription ?? illustration?.imageDescription;
    final hasFollowingLine = _lineIndex + 1 < widget.lines.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: spacing.md,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null && imageDescription != null) ...[
              Center(
                child: Semantics(
                  image: true,
                  label: illustration == null
                      ? imageDescription
                      : '${illustration.title}. $imageDescription',
                  child: ExcludeSemantics(
                    child: Image.asset(
                      imageAsset,
                      height: 240,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing.md),
            ],
            Semantics(
              container: true,
              liveRegion: true,
              label: line.hasSpeech
                  ? '${line.character.name} diz: ${line.text}'
                  : '${line.character.name}. ${line.text}',
              child: ExcludeSemantics(
                child: DvxGameCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          line.character.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      Text(line.text),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.lg),
            KeyboardNavigationLabel(
              label: hasFollowingLine
                  ? 'Continuar para '
                        '${widget.lines[_lineIndex + 1].hasSpeech ? 'a fala de ' : 'a cena de '}'
                        '${widget.lines[_lineIndex + 1].character.name}'
                  : widget.continuationLabel,
              child: FilledButton(
                key: ValueKey(
                  hasFollowingLine
                      ? 'continue-to-${widget.lines[_lineIndex + 1].character.name}'
                      : 'continue-to-course',
                ),
                autofocus: widget.autofocusContinue,
                onPressed: _continue,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
        widget.narrationControls(cues: line.cues),
      ],
    );
  }
}
