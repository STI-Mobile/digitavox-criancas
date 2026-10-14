import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_profile_repository.dart';
import '../support/recording_audio_guidance.dart';

void main() {
  testWidgets(
    'profile, mission orientation, practice, retry and saved approval',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final audio = RecordingAudioGuidance();
      final profiles = FakeProfileRepository();
      await tester.pumpWidget(
        DigitavoxApp(
          courseCatalog: const AssetCourseCatalog(
            assetPath: 'assets/content/demo_course.json',
          ),
          profileRepository: profiles,
          audioGuidance: audio,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cadete'));
      await tester.pumpAndSettle();
      expect(find.text('DEMO'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Aviso: conteúdo de demonstração')),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(ElevatedButton, 'Começar curso'));
      expect(find.text('Sensores da Aurora'), findsWidgets);
      expect(find.text('F'), findsNothing);
      await _tap(tester, find.widgetWithText(ElevatedButton, 'Começar missão'));
      expect(find.text('F'), findsOneWidget);
      expect(
        audio.playedCues.whereType<SpeechCue>().map((cue) => cue.audioAsset),
        contains('assets/audio/demo/instruction_f_demo.wav'),
      );
      for (final character in ['x', 'f', 'f']) {
        await _key(tester, character);
      }
      expect(find.text('Exercício concluído!'), findsOneWidget);
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Próximo exercício'),
      );
      expect(find.text('Exercício 2 de 2'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await _key(tester, 'j');
      }
      expect(find.text('Vamos praticar mais'), findsOneWidget);
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Praticar novamente'),
      );
      for (var i = 0; i < 3; i++) {
        await _key(tester, 'f');
      }
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Próximo exercício'),
      );
      for (var i = 0; i < 3; i++) {
        await _key(tester, 'j');
      }
      expect(find.text('Missão concluída!'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Você ganhou 3 de 3 estrelas.'),
        findsOneWidget,
      );
      expect(
        (await profiles.progress.load())
            .courses['demo-space-explorers']!
            .lessons['demo-sensors']!
            .stars,
        3,
      );
      await _tap(tester, find.widgetWithText(FilledButton, 'Próxima missão'));
      expect(find.text('Asa Esquerda'), findsWidgets);
      expect(find.text('A S D F G'), findsNothing);
      expect(audio.events, contains('cancel'));
      semantics.dispose();
    },
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, String character) async {
  final key = {
    'x': LogicalKeyboardKey.keyX,
    'f': LogicalKeyboardKey.keyF,
    'j': LogicalKeyboardKey.keyJ,
  }[character]!;
  await tester.sendKeyEvent(key, character: character);
  await tester.pumpAndSettle();
}
