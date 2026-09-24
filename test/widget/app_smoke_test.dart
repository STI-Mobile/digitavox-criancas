import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recording_audio_guidance.dart';

void main() {
  testWidgets('runs a physical-key exercise and records completion', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final audio = RecordingAudioGuidance();

    await tester.pumpWidget(
      DigitavoxApp(
        courseCatalog: const AssetCourseCatalog(
          assetPath: 'assets/content/demo_course.json',
        ),
        progressRepository: InMemoryProgressRepository(),
        audioGuidance: audio,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Digitavox'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);
    expect(find.bySemanticsLabel('0 estrelas conquistadas'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Aviso: conteúdo de demonstração')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Começar curso'));
    await tester.pumpAndSettle();

    expect(find.text('Tecla F'), findsWidgets);
    expect(find.text('F'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Próxima tecla: f')), findsOneWidget);
    expect(
      audio.playedCues.whereType<SpeechCue>().map((cue) => cue.audioAsset),
      contains('assets/audio/demo/instruction_f_demo.wav'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.keyX, character: 'x');
    await tester.pump();

    expect(find.text('Repetição 2 de 3'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Tecla x incorreta. Era f')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
    await tester.pumpAndSettle();

    expect(find.text('Tecla J'), findsOneWidget);
    expect(find.text('Exercício 2 de 2'), findsOneWidget);
    expect(
      (audio.playedCues.last as SpeechCue).audioAsset,
      'assets/audio/demo/instruction_j_demo.wav',
    );
    for (var index = 0; index < 3; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ, character: 'j');
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Asa Esquerda'), findsWidgets);
    await tester.tap(find.byTooltip('Voltar ao módulo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lição 1 · Sensores da Aurora'));
    await tester.pumpAndSettle();
    expect(find.text('2 de 2 exercícios concluídos'), findsOneWidget);
    expect(find.textContaining('Concluído · Refazer exercício'), findsWidgets);
    final course = find.widgetWithText(TextButton, 'Voltar ao curso');
    await tester.ensureVisible(course);
    await tester.pumpAndSettle();
    await tester.tap(course);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('2 estrelas conquistadas'), findsOneWidget);
    expect(audio.events, anyOf(contains('stop'), contains('cancel')));
    semantics.dispose();
  });
}
