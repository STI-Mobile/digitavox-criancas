import 'dart:convert';
import 'dart:io';

import 'package:digitavox_criancas/src/application/course_audio_orchestrator.dart';
import 'package:digitavox_criancas/src/application/course_catalog_view_model.dart';
import 'package:digitavox_criancas/src/application/course_journey_engine.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:digitavox_criancas/src/presentation/course_journey_screen.dart';
import 'package:digitavox_criancas/src/presentation/course_scene.dart';
import 'package:digitavox_criancas/src/presentation/design_system/app_theme/dvx_app_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/components/dvx_game_components.dart';
import 'package:digitavox_criancas/src/presentation/keyboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/journey_fixture.dart';
import '../support/recording_audio_guidance.dart';

void main() {
  late CourseCatalogViewModel catalog;
  late CourseJourneyEngine engine;
  late RecordingAudioGuidance audio;

  tearDown(() async {
    engine.dispose();
    catalog.dispose();
    await audio.dispose();
  });

  Future<void> pumpJourney(WidgetTester tester, {CourseCatalog? source}) async {
    catalog = CourseCatalogViewModel(
      courseCatalog: source ?? JourneyFixtureCatalog(),
      progressRepository: InMemoryProgressRepository(),
    );
    await catalog.initialize();
    audio = RecordingAudioGuidance();
    engine = CourseJourneyEngine(
      course: catalog.courses.single,
      catalog: catalog,
      courseAudio: CourseAudioOrchestrator(audioGuidance: audio),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.standard),
        home: CourseJourneyScreen(
          engine: engine,
          onThemePreferenceChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startMission(WidgetTester tester) async {
    await tester.tap(find.text('Começar curso'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Começar missão'));
    await tester.tap(find.text('Começar missão'));
    await tester.pumpAndSettle();
  }

  testWidgets('briefing illustration disappears before practice and results', (
    tester,
  ) async {
    await pumpJourney(tester);
    await tester.tap(find.text('Começar curso'));
    await tester.pumpAndSettle();
    expect(engine.stage, JourneyStage.lesson);
    expect(find.byType(CourseScene), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Ouvir apresentação'), findsOneWidget);
    await tester.ensureVisible(find.text('Começar missão'));
    await tester.tap(find.text('Começar missão'));
    await tester.pumpAndSettle();
    expect(find.byType(CourseScene), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Exercício 1 de 3'), findsOneWidget);
    expect(find.text('Ouvir apresentação'), findsNothing);
    expect(find.byTooltip('Alterar tema visual'), findsNothing);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'entrada do exercício',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
    await tester.pumpAndSettle();
    expect(engine.session!.completionError, isNull);
    expect(
      engine.session!.totalInputs,
      1,
      reason: engine.session!.announcement,
    );
    expect(find.text('Exercício concluído!'), findsOneWidget);
    expect(find.text('Exercício 1 de 3'), findsNothing);
    expect(find.byType(DvxKeyPrompt), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(_focusedLabel(), 'Próximo exercício');
    expect(tester.takeException(), isNull);
  });

  testWidgets('pauses without accepting input and restores the typing focus', (
    tester,
  ) async {
    await pumpJourney(tester);
    await startMission(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_focusedLabel(), 'Pausar prática');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(engine.session!.isPaused, isTrue);
    expect(_focusedLabel(), 'Retomar prática');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
    await tester.pump();
    expect(engine.session!.typedInput, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(engine.session!.isPaused, isFalse);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'entrada do exercício',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(engine.session!.isPaused, isTrue);
    expect(find.text('Ajuda · tempo pausado'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(engine.session!.isPaused, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mission result keeps the diary behind one named action', (
    tester,
  ) async {
    await pumpJourney(tester);
    await startMission(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ, character: 'j');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ, character: 'j');
    await tester.pumpAndSettle();
    expect(find.text('Missão concluída!'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Você ganhou 3 de 3 estrelas.'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('Precisão média:'), findsNothing);
    expect(_focusedLabel(), 'Próxima missão');
    await tester.ensureVisible(find.text('Ouvir diário de bordo'));
    await tester.tap(find.text('Ouvir diário de bordo'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Diário de bordo'), findsOneWidget);
    expect(find.textContaining('Precisão'), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canonical mission prerequisites disable future missions', (
    tester,
  ) async {
    await pumpJourney(
      tester,
      source: JourneyFixtureCatalog(
        jsonDecode(
          File('assets/content/exploradores_espaciais.json').readAsStringSync(),
        ) as Map<String, Object?>,
      ),
    );
    final module = engine.course.modules.first;
    engine.openModule(module);
    await tester.pumpAndSettle();
    final nextMission = find.widgetWithText(
      OutlinedButton,
      module.lessons[1].title,
    );
    expect(tester.widget<OutlinedButton>(nextMission).onPressed, isNull);
    expect(
      tester
          .getSemantics(nextMission)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    expect(_focusedLabel(), startsWith(module.lessons.first.title));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_focusedLabel(), 'Voltar ao curso');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'briefing start stays visible with narrow screen and enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpJourney(
        tester,
        source: JourneyFixtureCatalog(
          jsonDecode(
            File('assets/content/exploradores_espaciais.json')
                .readAsStringSync(),
          ) as Map<String, Object?>,
        ),
      );
      engine.resume();
      await tester.pumpAndSettle();
      final start = find.widgetWithText(ElevatedButton, 'Começar missão');
      expect(tester.getRect(start).bottom, lessThanOrEqualTo(800));
      expect(tester.getRect(start).top, greaterThanOrEqualTo(0));
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

  testWidgets('long targets keep enlarged text and wrap on a narrow display', (
    tester,
  ) async {
    await pumpJourney(tester);
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.highContrast),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: DvxKeyPrompt(value: 'as asas da sala', nextCharacter: 'a'),
          ),
        ),
      ),
    );
    expect(find.text('AS ASAS DA SALA'), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

String? _focusedLabel() => FocusManager.instance.primaryFocus?.context
    ?.findAncestorWidgetOfExactType<KeyboardNavigationLabel>()
    ?.label;
