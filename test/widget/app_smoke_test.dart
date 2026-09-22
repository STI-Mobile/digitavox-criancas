import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runs a physical-key exercise and records completion', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      DigitavoxApp(
        courseCatalog: const AssetCourseCatalog(
          assetPath: 'assets/content/demo_course.json',
        ),
        progressRepository: InMemoryProgressRepository(),
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

    await tester.tap(find.widgetWithText(ElevatedButton, 'Começar'));
    await tester.pumpAndSettle();

    expect(find.text('Tecla A'), findsWidgets);
    expect(find.text('Pressione'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('A tecla esperada é A')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.keyX, character: 'x');
    await tester.pump();

    expect(find.text('Tente novamente'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Tecla X incorreta')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pumpAndSettle();

    expect(find.text('Concluído'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Resposta correta. Exercício concluído.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('1 estrelas conquistadas'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Refazer'), findsOneWidget);
    semantics.dispose();
  });
}
