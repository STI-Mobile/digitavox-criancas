import 'dart:ui' show Tristate;

import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/application/audio/audio_coordinator.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_content_audio_service.dart';
import '../support/journey_fixture.dart';

void main() {
  testWidgets(
    'browses the hierarchy and exposes named, operable semantic buttons',
    (tester) async {
      await _pumpDemo(tester);
      final module = find.widgetWithText(
        OutlinedButton,
        'Módulo 1 · O Despertar da Aurora',
      );
      final node = tester.getSemantics(module);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.flagsCollection.isButton, isTrue);
      await tester.tap(module);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lição 1 · Sensores da Aurora'));
      await tester.pumpAndSettle();
      expect(find.text('1. Tecla F'), findsOneWidget);
      expect(find.text('2. Tecla J'), findsOneWidget);
      await tester.tap(find.text('2. Tecla J'));
      await tester.pumpAndSettle();
      expect(find.text('Exercício 2 de 2'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('0 de 2 exercícios concluídos'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Lição 1 · Sensores da Aurora'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Digitavox'), findsOneWidget);
      expect(find.bySemanticsLabel('0 estrelas conquistadas'), findsOneWidget);
    },
  );

  testWidgets(
    'unavailable activities are inspectable and explicitly disabled',
    (tester) async {
      await _pumpDemo(tester);
      await tester.tap(find.text('Módulo 1 · O Despertar da Aurora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lição 2 · Asa Esquerda'));
      await tester.pumpAndSettle();
      final activity = find.widgetWithText(
        OutlinedButton,
        '1. Código da Asa Esquerda',
      );
      expect(tester.widget<OutlinedButton>(activity).onPressed, isNull);
      expect(
        tester.getSemantics(activity).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(find.textContaining('Ainda não disponível'), findsWidgets);
      expect(find.text('Começar lição'), findsNothing);
    },
  );

  testWidgets(
    'resumes saved progress and keeps continuation accessible by keyboard',
    (tester) async {
      final repository = InMemoryProgressRepository();
      await _pumpDemo(tester, repository: repository);
      await tester.tap(find.text('Começar curso'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Tecla J'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await _pumpDemo(tester, repository: repository);
      await tester.tap(find.text('Continuar curso'));
      await tester.pumpAndSettle();
      expect(find.text('Tecla J'), findsOneWidget);
      expect((await repository.load()).totalStars, 1);
    },
  );

  testWidgets(
    'JSON drives character and narration with a missing-image fallback',
    (tester) async {
      final service = FakeContentAudioService();
      await tester.pumpWidget(
        DigitavoxApp(
          courseCatalog: JourneyFixtureCatalog(),
          progressRepository: InMemoryProgressRepository(),
          audioCoordinator: AudioCoordinator(contentAudioService: service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bem-vindo à jornada de demonstração.'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Aurora. Personagem guia da jornada de demonstração.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(service.events.last, 'play:assets/audio/demo/welcome.wav');
      await tester.tap(find.text('Parar áudio'));
      await tester.pumpAndSettle();
      expect(service.events.last, 'stop');
      await tester.tap(find.text('Ouvir novamente'));
      await tester.pumpAndSettle();
      expect(service.events.last, 'play:assets/audio/demo/welcome.wav');
      await tester.ensureVisible(find.text('Começar curso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Começar curso'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
      await tester.pumpAndSettle();
      final next = find.text('Próximo exercício: Tecla J');
      await tester.scrollUntilVisible(next, 250);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          'Explorador. Personagem explorador da jornada de demonstração.',
        ),
        findsOneWidget,
      );
      expect(service.events.last, 'play:assets/audio/demo/key_j.wav');
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
    await _pumpDemo(tester);
    final module = find.text('Módulo 1 · O Despertar da Aurora');
    await tester.scrollUntilVisible(module, 250);
    await tester.pumpAndSettle();
    await tester.tap(module);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lição 1 · Sensores da Aurora'));
    await tester.pumpAndSettle();
    final start = find.text('Começar lição');
    await tester.scrollUntilVisible(start, 250);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    final keyboard = find.byTooltip('Ativar entrada pelo teclado físico');
    await tester.scrollUntilVisible(keyboard, 250);
    await tester.pumpAndSettle();
    await tester.tap(keyboard);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
    await tester.pumpAndSettle();
    final next = find.text('Próximo exercício: Tecla J');
    await tester.scrollUntilVisible(next, 250);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Tecla J'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDemo(
  WidgetTester tester, {
  InMemoryProgressRepository? repository,
}) async {
  // Cached asset futures belong to the fake-async zone of the test that loaded
  // them. Reload for each app instance instead of retaining a previous zone.
  rootBundle.evict('assets/content/demo_course.json');
  await tester.pumpWidget(
    DigitavoxApp(
      courseCatalog: const AssetCourseCatalog(
        assetPath: 'assets/content/demo_course.json',
      ),
      progressRepository: repository ?? InMemoryProgressRepository(),
      audioCoordinator: AudioCoordinator(
        contentAudioService: FakeContentAudioService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
