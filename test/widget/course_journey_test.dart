import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/application/audio/audio_coordinator.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:digitavox_criancas/src/presentation/design_system/tokens/dvx_tokens.dart';
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

  testWidgets('sequence activities are driven by the catalog', (tester) async {
    await _pumpDemo(tester);
    await tester.tap(find.text('Módulo 1 · O Despertar da Aurora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lição 2 · Asa Esquerda'));
    await tester.pumpAndSettle();
    final activity = find.widgetWithText(
      OutlinedButton,
      '1. Código da Asa Esquerda',
    );
    expect(tester.widget<OutlinedButton>(activity).onPressed, isNotNull);
    await tester.tap(activity);
    await tester.pumpAndSettle();
    expect(find.text('ASDFG'), findsOneWidget);
    expect(find.text('Repetição 1 de 3'), findsOneWidget);
  });

  testWidgets(
    'resumes saved progress and keeps continuation accessible by keyboard',
    (tester) async {
      final repository = InMemoryProgressRepository();
      await _pumpDemo(tester, repository: repository);
      await tester.tap(find.text('Começar curso'));
      await tester.pumpAndSettle();
      for (var index = 0; index < 3; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
        await tester.pump();
      }
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
    'JSON drives character assets, narration and missing-image fallback',
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
      expect(find.byType(Image), findsOneWidget);
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
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ, character: 'j');
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          'Explorador. Personagem explorador da jornada de demonstração.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
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
    final keyboard = find.text('Ativar teclado');
    await tester.scrollUntilVisible(keyboard, 250);
    await tester.pumpAndSettle();
    await tester.tap(keyboard);
    for (var index = 0; index < 3; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Tecla J'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports exercise shortcuts and Escape navigation', (
    tester,
  ) async {
    await _pumpDemo(tester);
    await tester.tap(find.text('Começar curso'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    expect(find.bySemanticsLabel('Próxima tecla: f.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pumpAndSettle();
    expect(find.text('Atalhos do exercício'), findsOneWidget);
    expect(find.textContaining('F9 — tempo'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Sensores da Aurora'), findsWidgets);
    expect(find.text('0 de 2 exercícios concluídos'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Lição 1 · Sensores da Aurora'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Digitavox'), findsOneWidget);
  });

  testWidgets('switches and persists Standard, Dark and High Contrast', (
    tester,
  ) async {
    final repository = InMemoryProgressRepository();
    await _pumpDemo(tester, repository: repository);
    var context = tester.element(find.text('Digitavox'));
    expect(Theme.of(context).brightness, Brightness.light);

    await tester.tap(find.byTooltip('Alterar tema visual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    context = tester.element(find.text('Digitavox'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      (await repository.load()).settings.themePreference,
      AppThemePreference.dark,
    );

    await tester.tap(find.byTooltip('Alterar tema visual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();
    context = tester.element(find.text('Digitavox'));
    expect(Theme.of(context).extension<DvxThemeTokens>()!.highContrast, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _pumpDemo(tester, repository: repository);
    context = tester.element(find.text('Digitavox'));
    expect(Theme.of(context).extension<DvxThemeTokens>()!.highContrast, isTrue);
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
