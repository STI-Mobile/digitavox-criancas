import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_audio_guidance.dart';

void main() {
  testWidgets('Demo Course conecta jornada, cues e cancelamento', (
    tester,
  ) async {
    final audio = RecordingAudioGuidance();
    await tester.pumpWidget(
      DigitavoxApp(
        courseCatalog: const AssetCourseCatalog(
          assetPath: 'assets/content/integration_demo_course.json',
        ),
        progressRepository: InMemoryProgressRepository(),
        audioGuidance: audio,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demo de Integração'), findsWidgets);
    expect(audio.playedCues.map((cue) => cue.id), contains('demo-start'));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Começar curso'));
    await tester.pumpAndSettle();

    expect(find.text('Entrada visual A.'), findsOneWidget);
    final instruction = audio.playedCues.whereType<SpeechCue>().firstWhere(
      (cue) => cue.id == 'press-a-instruction',
    );
    expect(instruction.text, 'Pressione a tecla A.');
    expect(instruction.audioAsset, 'assets/audio/demo/instruction_a_demo.wav');
    expect(instruction.speaker, 'demo-speaker');

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pumpAndSettle();

    expect(
      audio.playedCues.map((cue) => cue.id),
      containsAll(<String>['press-a-correct', 'press-a-completed']),
    );
    expect(find.text('Teste de segunda tecla'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Começar lição'));
    await tester.pumpAndSettle();
    final fallbackSpeech = audio.playedCues.whereType<SpeechCue>().firstWhere(
      (cue) => cue.id == 'press-f-instruction',
    );
    expect(fallbackSpeech.text, 'Pressione a tecla F.');
    expect(
      fallbackSpeech.audioAsset,
      'assets/audio/demo/missing_technical_demo.wav',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.keyX, character: 'x');
    await tester.pumpAndSettle();

    expect(
      audio.playedCues.whereType<SfxCue>().map((cue) => cue.id),
      contains('press-f-incorrect'),
    );
    expect(find.text('Teste de sequência'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Começar lição'));
    await tester.pumpAndSettle();
    expect(
      audio.playedCues.map((cue) => cue.id),
      contains('type-af-instruction'),
    );

    final cancellationsBefore = audio.events
        .where((event) => event == 'cancel')
        .length;
    await tester.tap(find.byTooltip('Voltar à lição'));
    await tester.pumpAndSettle();
    expect(
      audio.events.where((event) => event == 'cancel').length,
      greaterThan(cancellationsBefore),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Começar lição'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
    await tester.pumpAndSettle();

    expect(
      audio.sequences.map((sequence) => sequence.map((cue) => cue.id).toList()),
      contains(
        equals(<String>[
          'type-af-completed-start',
          'type-af-completed-signal',
          'type-af-completed-end',
        ]),
      ),
    );
  });
}
