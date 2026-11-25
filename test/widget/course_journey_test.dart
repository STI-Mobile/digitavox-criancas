import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
import 'package:digitavox_criancas/src/data/persistence/local_profile_repository.dart';
import 'package:digitavox_criancas/src/data/persistence/local_progress_repository.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:digitavox_criancas/src/presentation/course_journey_screen.dart';
import 'package:digitavox_criancas/src/presentation/design_system/app_theme/dvx_app_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/components/dvx_game_components.dart';
import 'package:digitavox_criancas/src/presentation/design_system/course_theme/course_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/tokens/accessibility_tokens.dart';
import 'package:digitavox_criancas/src/presentation/keyboard_navigation.dart';
import 'package:digitavox_criancas/src/presentation/scene_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/journey_fixture.dart';
import '../support/recording_audio_guidance.dart';

void main() {
  testWidgets(
    'character lines keep speaker, text and narration cues together',
    (tester) async {
      final audio = RecordingAudioGuidance();
      final json = journeyJson();
      final course = (json['courses'] as List).single as Map<String, Object?>;
      course['isDemo'] = false;
      final scene = course['scene'] as Map<String, Object?>;
      scene['instruction'] = 'Vamos explorar a jornada.';
      scene['narrationCues'] = [
        {
          'id': 'journey-start',
          'type': 'speech',
          'text': 'Bem-vindo à jornada de demonstração.',
          'asset': 'assets/audio/demo/welcome.wav',
          'speaker': 'aurora',
          'fallback': 'text',
        },
      ];
      scene['instructionCues'] = [
        {
          'id': 'journey-instruction',
          'type': 'speech',
          'text': 'Vamos explorar a jornada.',
          'asset': 'assets/audio/demo/preparation.wav',
          'speaker': 'explorer',
          'fallback': 'text',
        },
      ];

      await _pumpDemo(
        tester,
        repository: _createRepository(),
        audio: audio,
        catalog: JourneyFixtureCatalog(json),
      );

      expect(find.byType(SceneScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Aurora diz: Bem-vindo à jornada de demonstração.',
        ),
        findsOneWidget,
      );
      expect(audio.playedCues.whereType<SpeechCue>().last.id, 'journey-start');

      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Explorador diz: Vamos explorar a jornada.'),
        findsOneWidget,
      );
      expect(
        audio.playedCues.whereType<SpeechCue>().last.id,
        'journey-instruction',
      );

      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Começar curso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'course introduction shows Stella then ZERO-1 before the module list',
    (tester) async {
      final audio = RecordingAudioGuidance();
      await _pumpDemo(
        tester,
        repository: _createRepository(),
        catalog: JourneyFixtureCatalog(
          jsonDecode(
            File('assets/content/exploradores_espaciais.json')
                .readAsStringSync(),
          ) as Map<String, Object?>,
        ),
        audio: audio,
      );

      expect(
        find.textContaining('Uma tempestade solar varreu a galáxia'),
        findsOneWidget,
      );
      final stellaIllustration = find.bySemanticsLabel(
        'Aurora em emergência. Apresentação Stella.',
      );
      expect(stellaIllustration, findsOneWidget);
      expect(
        tester.getSemantics(stellaIllustration).flagsCollection.isImage,
        isTrue,
      );
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'assetName',
          'assets/images/space/module1/cenas-16x9/c0_f1_stella.jpg',
        ),
      );
      expect(find.textContaining('Bip! Zero Um na escuta'), findsNothing);
      expect(audio.playedCues.whereType<SpeechCue>().single.id, 'm1c0-stella');

      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Uma tempestade solar varreu a galáxia'),
        findsNothing,
      );
      expect(find.textContaining('Bip! Zero Um na escuta'), findsOneWidget);
      expect(audio.playedCues.whereType<SpeechCue>().last.id, 'm1c0-zero1');
      expect(
        find.bySemanticsLabel('Aurora em emergência. Apresentação Zero-1.'),
        findsOneWidget,
      );
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'assetName',
          'assets/images/space/module1/cenas-16x9/c0_f2_zero1.jpg',
        ),
      );

      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Módulo 1 · A Nave Adormecida'), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'test profile can complete a mission without entering its exercises',
    (tester) async {
      final repository = _createRepository();
      await _pumpDemo(tester, repository: repository, profileName: 'Felipaoao');
      await _startCourse(tester);

      expect(find.text('Concluir missão (teste)'), findsOneWidget);
      await tester.ensureVisible(find.text('Concluir missão (teste)'));
      await tester.tap(find.text('Concluir missão (teste)'));
      await tester.pumpAndSettle();

      expect(find.text('Concluir missão (teste)'), findsNothing);
      expect(find.text('Concluída · Praticar novamente'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('normal profiles do not see the mission test button', (
    tester,
  ) async {
    await _pumpDemo(
      tester,
      repository: _createRepository(),
      profileName: 'Perfil normal',
    );
    await _startCourse(tester);

    expect(find.text('Concluir missão (teste)'), findsNothing);
  });

  testWidgets('ceremony rewards show the three aliens in order', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.standard),
        home: DvxGameScaffold(
          courseTheme: DvxCourseThemes.resolve('space')
              .resolve(AppThemePreference.standard),
          title: 'Conclusão do módulo',
          body: const CeremonyRewards(
            rewardLabels: ['Cadete de Bronze', 'Blib-Blub', 'Zorp', 'Nebulon'],
          ),
        ),
      ),
    );
    await tester.pump();

    final images = tester
        .widgetList<Image>(find.byType(Image))
        .whereType<Image>()
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    expect(images, [
      'assets/images/space/module1/alien_zorp_acenando.png',
      'assets/images/space/module1/alien_nebulon_frente.png',
      'assets/images/space/module1/alien_blib_blub_acenando_esquerda.png',
    ]);
    expect(find.text('Cadete de Bronze'), findsOneWidget);
    expect(find.text('Zorp'), findsNothing);
    expect(find.text('Nebulon'), findsNothing);
    expect(find.text('Blib-Blub'), findsNothing);

    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel('Zorp, acenando, posicionado à esquerda'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Nebulon, de frente, posicionado ao centro'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Blib-Blub, acenando à esquerda, posicionado à direita',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'keyboard menus cycle, announce selection and activate with Enter',
    (tester) async {
      final audio = RecordingAudioGuidance();
      await _pumpDemo(tester, repository: _createRepository(), audio: audio);
      expect(_focusedLabel(), 'Começar curso');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), startsWith('O Despertar da Aurora'));
      expect((audio.playedCues.last as SpeechCue).text, _focusedLabel());
      expect(audio.events, contains('cancel'));

      // Reverse traversal agrees with Shift+Tab.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Começar curso');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Alterar tema visual. Escuro');

      // Wrap from the first toolbar control to the course-introduction action.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Rever introdução do curso');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Alterar tema visual. Escuro');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), startsWith('Sensores da Aurora'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Começar missão');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'entrada do exercício',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'exercise focus moves to continuation and no longer captures buttons',
    (tester) async {
      final audio = RecordingAudioGuidance();
      await _pumpDemo(tester, repository: _createRepository(), audio: audio);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'entrada do exercício',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect((audio.playedCues.last as SpeechCue).text, 'Próxima tecla: f.');

      // Tab leaves typing; arrows and Space operate native controls there.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Pausar prática');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Ajuda F1');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space, character: ' ');
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Retomar prática');
      await tester.sendKeyEvent(LogicalKeyboardKey.space, character: ' ');
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'entrada do exercício',
      );
      expect(find.text('Repetição 1 de 3'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Próximo exercício');
      final semantics = tester.getSemantics(
        find.widgetWithText(FilledButton, 'Próximo exercício'),
      );
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isFocused, Tristate.isTrue);
      final sequenceCount = audio.sequences.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Voltar à missão');
      expect(audio.sequences.length, sequenceCount + 1);
      expect((audio.playedCues.last as SpeechCue).text, 'Voltar à missão');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Próximo exercício');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Exercício 2 de 2'), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'entrada do exercício',
      );
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ, character: 'j');
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Próxima missão');
      await tester.sendKeyEvent(LogicalKeyboardKey.space, character: ' ');
      await tester.pumpAndSettle();
      expect(find.text('Asa Esquerda'), findsWidgets);
      expect(_focusedLabel(), 'Começar missão');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard navigation scrolls to offscreen actions with large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpDemo(tester, repository: _createRepository());
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), startsWith('O Despertar da Aurora'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), startsWith('Asa Esquerda'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Asa Esquerda'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'profile actions are named and selectable with arrows and Enter',
    (tester) async {
      final repository = _createRepository();
      await repository.createProfile('Ana');
      await repository.createProfile('Bia');
      final audio = RecordingAudioGuidance();
      await tester.pumpWidget(
        DigitavoxApp(
          courseCatalog: JourneyFixtureCatalog(),
          profileRepository: repository,
          audioGuidance: audio,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Ana'))).brightness,
        Brightness.dark,
      );
      expect(_focusedLabel(), 'Aprender com Ana');
      final select = tester.getSemantics(find.text('Ana'));
      expect(select.flagsCollection.isButton, isTrue);
      expect(select.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Excluir perfil de Ana');
      final delete = tester.getSemantics(
        find.bySemanticsLabel('Excluir perfil de Ana'),
      );
      expect(delete.flagsCollection.isButton, isTrue);
      expect(delete.label, 'Excluir perfil de Ana');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedLabel(), 'Aprender com Bia');
      expect((audio.playedCues.last as SpeechCue).text, 'Aprender com Bia');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Começar curso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restores click feedback during typing and keeps it off menu actions',
    (tester) async {
      final audio = RecordingAudioGuidance();
      await _pumpDemo(tester, repository: _createRepository(), audio: audio);
      await _startCourse(tester);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'entrada do exercício',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
      await tester.pumpAndSettle();
      expect((audio.playedCues.last as SpeechCue).text, 'f');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX, character: 'x');
      await tester.pumpAndSettle();
      expect(audio.playedCues.whereType<ClickCue>().last.doubleClick, isTrue);
      expect(
        find.bySemanticsLabel(RegExp('Tecla x incorreta')),
        findsOneWidget,
      );
      final clicksBefore = audio.playedCues.whereType<ClickCue>().length;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space, character: ' ');
      await tester.pumpAndSettle();
      expect(audio.playedCues.whereType<ClickCue>().length, clicksBefore);
      expect(_focusedLabel(), 'Retomar prática');
      await tester.sendKeyEvent(LogicalKeyboardKey.space, character: ' ');
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'entrada do exercício',
      );
    },
  );

  testWidgets(
    'browses the hierarchy and exposes named, operable semantic buttons',
    (tester) async {
      final repository = _createRepository();

      await _pumpDemo(tester, repository: repository);

      final module = find.widgetWithText(
        OutlinedButton,
        'O Despertar da Aurora',
      );

      final node = tester.getSemantics(module);

      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.flagsCollection.isButton, isTrue);

      await tester.tap(module);
      await tester.pumpAndSettle();

      final missionTile = find.widgetWithText(
        OutlinedButton,
        'Sensores da Aurora',
      );
      expect(
        find.descendant(
          of: missionTile,
          matching: find.byIcon(Icons.star_outline_rounded),
        ),
        findsNWidgets(3),
      );
      expect(
        tester.getSemantics(missionTile).label,
        contains('Melhor resultado: 0 de 3 estrelas.'),
      );

      await tester.tap(find.text('Sensores da Aurora'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exercícios da missão'));
      await tester.pumpAndSettle();
      expect(find.text('1. Tecla F'), findsOneWidget);
      final locked = find.widgetWithText(OutlinedButton, '2. Tecla J');
      expect(tester.widget<OutlinedButton>(locked).onPressed, isNull);

      await tester.tap(find.text('1. Tecla F'));
      await tester.pumpAndSettle();

      expect(find.text('Exercício 1 de 2'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Começar missão'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(OutlinedButton, 'Sensores da Aurora'),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Digitavox'), findsOneWidget);
      expect(find.text('0 de 4 missões concluídas'), findsOneWidget);
    },
  );

  testWidgets(
    'shows lesson completion only after all lesson exercises are recorded',
    (tester) async {
      await _pumpDemo(tester, repository: _createRepository());

      await _startCourse(tester);

      for (var index = 0; index < 3; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('Exercício concluído!'), findsOneWidget);
      expect(find.text('Missão concluída!'), findsNothing);

      await tester.tap(find.text('Próximo exercício'));
      await tester.pumpAndSettle();

      for (var index = 0; index < 3; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyJ, character: 'j');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('Missão concluída!'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Você ganhou 3 de 3 estrelas.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.star), findsNWidgets(6));
      expect(find.textContaining('Precisão 100'), findsNothing);
      await tester.ensureVisible(find.text('Ouvir diário de bordo'));
      await tester.tap(find.text('Ouvir diário de bordo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Precisão 100'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Fechar diário'));
      await tester.pumpAndSettle();
      expect(find.text('Próxima missão'), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar à missão'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar ao módulo'));
      await tester.pumpAndSettle();
      final completedMission = find.widgetWithText(
        OutlinedButton,
        'Sensores da Aurora',
      );
      expect(
        find.descendant(
          of: completedMission,
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsNWidgets(3),
      );
      expect(
        find.descendant(
          of: completedMission,
          matching: find.byIcon(Icons.star_outline_rounded),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('requires retrying a lesson when its accuracy earns no stars', (
    tester,
  ) async {
    await _pumpDemo(tester, repository: _createRepository());
    await _startCourse(tester);

    for (final key in <(LogicalKeyboardKey, String)>[
      (LogicalKeyboardKey.keyF, 'f'),
      (LogicalKeyboardKey.keyX, 'x'),
      (LogicalKeyboardKey.keyF, 'f'),
    ]) {
      await tester.sendKeyEvent(key.$1, character: key.$2);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Próximo exercício'));
    await tester.pumpAndSettle();

    for (final key in <(LogicalKeyboardKey, String)>[
      (LogicalKeyboardKey.keyJ, 'j'),
      (LogicalKeyboardKey.keyX, 'x'),
      (LogicalKeyboardKey.keyJ, 'j'),
    ]) {
      await tester.sendKeyEvent(key.$1, character: key.$2);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Vamos praticar mais'), findsOneWidget);
    expect(find.text('Missão concluída!'), findsNothing);
    expect(find.text('Praticar novamente'), findsOneWidget);
    expect(_focusedLabel(), 'Praticar novamente');
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Exercício 1 de 2'), findsOneWidget);
    expect(find.text('Exercício concluído!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sequence activities are driven by the catalog', (tester) async {
    final repository = _createRepository();

    await _pumpDemo(tester, repository: repository);

    await tester.tap(find.text('O Despertar da Aurora'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asa Esquerda'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exercícios da missão'));
    await tester.pumpAndSettle();
    final activity = find.widgetWithText(
      OutlinedButton,
      '1. Código da Asa Esquerda',
    );

    expect(tester.widget<OutlinedButton>(activity).onPressed, isNotNull);

    await tester.tap(activity);
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Repetição 1 de 3'), findsOneWidget);
  });

  testWidgets(
    'resumes saved progress and keeps continuation accessible by keyboard',
    (tester) async {
      final repository = _createRepository();

      await _pumpDemo(tester, repository: repository);

      await _startCourse(tester);

      for (var index = 0; index < 3; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
        await tester.pump();
      }

      await tester.pumpAndSettle();
      expect(find.text('Exercício concluído!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await _pumpDemo(tester, repository: repository);

      await tester.tap(find.text('Continuar curso'));
      await tester.pumpAndSettle();

      expect(find.text('Continuar missão'), findsOneWidget);
      await tester.tap(find.text('Continuar missão'));
      await tester.pumpAndSettle();
      expect(find.text('Exercício 2 de 2'), findsOneWidget);
    },
  );

  testWidgets(
    'JSON controls briefing narration and missing artwork never blocks practice',
    (tester) async {
      final audio = RecordingAudioGuidance();
      final json = journeyJson();
      final course = (json['courses'] as List).single as Map<String, Object?>;
      final module = (course['modules'] as List).first as Map<String, Object?>;
      final lesson = (module['lessons'] as List).first as Map<String, Object?>;
      final scene = lesson['scene'] as Map<String, Object?>;
      scene['characterId'] = 'explorer';
      scene['audioGuidance'] = {
        'start': [
          {
            'id': 'lesson-start',
            'type': 'speech',
            'text': 'Encontre as marcas das teclas F e J.',
            'speaker': 'explorer',
            'asset': 'assets/audio/demo/sensors.wav',
            'fallback': 'text',
          },
        ],
      };
      await _pumpDemo(
        tester,
        repository: _createRepository(),
        audio: audio,
        catalog: JourneyFixtureCatalog(json),
      );
      expect(
        (audio.playedCues.last as SpeechCue).audioAsset,
        'assets/audio/demo/welcome.wav',
      );
      expect(find.byType(DvxNarrationControls), findsNothing);
      await tester.ensureVisible(find.text('Começar curso'));
      await tester.tap(find.text('Começar curso'));
      await tester.pumpAndSettle();
      expect(find.byType(DvxNarrationControls), findsOneWidget);
      expect((audio.playedCues.last as SpeechCue).id, 'lesson-start');
      await tester.ensureVisible(find.text('Parar áudio'));
      await tester.tap(find.text('Parar áudio'));
      await tester.pumpAndSettle();
      expect(audio.events.last, 'cancel');
      await tester.ensureVisible(find.text('Ouvir apresentação'));
      await tester.tap(find.text('Ouvir apresentação'));
      await tester.pumpAndSettle();
      expect((audio.playedCues.last as SpeechCue).id, 'lesson-start');
      expect(find.byType(SceneScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Explorador diz: Encontre as marcas das teclas F e J.',
        ),
        findsOneWidget,
      );
      expect(find.byType(Image), findsNothing);
      await tester.ensureVisible(find.text('Começar missão'));
      await tester.tap(find.text('Começar missão'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(
        (audio.playedCues.last as SpeechCue).audioAsset,
        'assets/audio/demo/key_f.wav',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('supports large text on a narrow screen throughout navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final repository = _createRepository();

    await _pumpDemo(tester, repository: repository);

    final module = find.text('O Despertar da Aurora');

    await tester.scrollUntilVisible(module, 250);
    await tester.pumpAndSettle();

    await tester.tap(module);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sensores da Aurora'));
    await tester.pumpAndSettle();

    final start = find.text('Começar missão');

    await tester.scrollUntilVisible(start, 250);
    await tester.pumpAndSettle();

    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'entrada do exercício',
    );

    for (var index = 0; index < 3; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
      await tester.pump();
    }

    await tester.pumpAndSettle();

    expect(find.text('Exercício concluído!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports exercise shortcuts and Escape navigation', (
    tester,
  ) async {
    final repository = _createRepository();

    await _pumpDemo(tester, repository: repository);

    await _startCourse(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();

    expect(find.bySemanticsLabel('Próxima tecla: f.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();

    expect(find.text('Ajuda · tempo pausado'), findsOneWidget);
    expect(find.textContaining('F9 — tempo'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Sensores da Aurora'), findsWidgets);
    expect(find.text('Começar missão'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(OutlinedButton, 'Sensores da Aurora'),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Digitavox'), findsOneWidget);
  });

  testWidgets(
    'announces each theme during keyboard navigation before applying it',
    (tester) async {
      final audio = RecordingAudioGuidance();
      final repository = _createRepository();
      await _pumpDemo(tester, repository: repository, audio: audio);
      await tester.tap(find.byTooltip('Alterar tema visual'));
      await tester.pumpAndSettle();
      final initialCueCount = audio.sequences.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect((audio.playedCues.last as SpeechCue).text, 'Claro');
      expect(
        tester.getSemantics(find.text('Escuro')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(find.text('Claro')).flagsCollection.isSelected,
        Tristate.isFalse,
      );
      expect(audio.sequences.length, initialCueCount + 1);
      expect(
        Theme.of(tester.element(find.text('Digitavox'))).brightness,
        Brightness.dark,
      );
      final profile = (await repository.loadProfiles()).single;
      expect(
        (await repository.progressFor(profile).load()).settings.themePreference,
        AppThemePreference.dark,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect((audio.playedCues.last as SpeechCue).text, 'Escuro');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect((audio.playedCues.last as SpeechCue).text, 'Alto contraste');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect((audio.playedCues.last as SpeechCue).text, 'Escuro');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect((audio.playedCues.last as SpeechCue).text, 'Claro');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        (await repository.progressFor(profile).load()).settings.themePreference,
        AppThemePreference.dark,
      );
      expect(find.text('Padrão'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('starts dark and persists Claro, Escuro and Alto contraste', (
    tester,
  ) async {
    final repository = _createRepository();

    await _pumpDemo(tester, repository: repository);

    var context = tester.element(find.text('Digitavox'));

    expect(Theme.of(context).brightness, Brightness.dark);

    await tester.tap(find.byTooltip('Alterar tema visual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Digitavox'))).brightness,
      Brightness.light,
    );
    final profileWithLightTheme = (await repository.loadProfiles()).single;
    expect(
      (await repository.progressFor(profileWithLightTheme).load())
          .settings
          .themePreference,
      AppThemePreference.standard,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _pumpDemo(tester, repository: repository);
    expect(
      Theme.of(tester.element(find.text('Digitavox'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byTooltip('Alterar tema visual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    context = tester.element(find.text('Digitavox'));

    expect(Theme.of(context).brightness, Brightness.dark);

    final profile = (await repository.loadProfiles()).single;
    final progressRepository = repository.progressFor(profile);
    final progressAfterDark = await progressRepository.load();

    expect(progressAfterDark.settings.themePreference, AppThemePreference.dark);

    await tester.tap(find.byTooltip('Alterar tema visual'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();

    context = tester.element(find.text('Digitavox'));

    expect(
      Theme.of(context).extension<DvxAccessibilityTokens>()!.highContrast,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpDemo(tester, repository: repository);

    context = tester.element(find.text('Digitavox'));

    expect(
      Theme.of(context).extension<DvxAccessibilityTokens>()!.highContrast,
      isTrue,
    );
  });
}

Future<void> _startCourse(WidgetTester tester) async {
  if (find.text('Continuar').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text('Começar curso'));
  await tester.tap(find.text('Começar curso'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Começar missão'));
  await tester.tap(find.text('Começar missão'));
  await tester.pumpAndSettle();
}

Future<void> _pumpDemo(
  WidgetTester tester, {
  required LocalProfileRepository repository,
  CourseCatalog? catalog,
  RecordingAudioGuidance? audio,
  String profileName = 'Perfil de teste',
}) async {
  final profiles = await repository.loadProfiles();

  final profile = profiles.isEmpty
      ? await repository.createProfile(profileName)
      : profiles.first;

  rootBundle.evict('assets/content/demo_course.json');

  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    DigitavoxApp(
      courseCatalog:
          catalog ??
          const AssetCourseCatalog(
            assetPath: 'assets/content/demo_course.json',
          ),
      profileRepository: repository,
      audioGuidance: audio ?? RecordingAudioGuidance(),
    ),
  );

  await tester.pumpAndSettle();

  await tester.tap(find.text(profile.name));
  await tester.pumpAndSettle();
}

LocalProfileRepository _createRepository() {
  final stores = <String, _MemoryDocumentStore>{};
  return LocalProfileRepository(
    profilesStore: _MemoryDocumentStore(),
    progressStoreFor: (id) => stores.putIfAbsent(id, _MemoryDocumentStore.new),
  );
}

final class _MemoryDocumentStore implements ProgressDocumentStore {
  String? _document;

  @override
  Future<String?> read() async => _document;

  @override
  Future<void> write(String document) async {
    _document = document;
  }
}

String? _focusedLabel() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<KeyboardNavigationLabel>()
    ?.label;
