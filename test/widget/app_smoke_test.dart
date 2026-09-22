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

    expect(find.text('Digitavox Crianças'), findsOneWidget);
    expect(find.textContaining('CONTEÚDO DEMO'), findsOneWidget);
    expect(find.text('Estrelas: 0'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Aviso: conteúdo de demonstração')),
      findsOneWidget,
    );

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Iniciar Pressionar a tecla A'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercício de tecla'), findsOneWidget);
    expect(find.text('Tecla esperada: A'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('A tecla esperada é A')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.keyX, character: 'x');
    await tester.pump();

    expect(find.text('Tecla X incorreta. Tente novamente.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pumpAndSettle();

    expect(find.text('Correto. Exercício concluído.'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Voltar à lição'));
    await tester.pumpAndSettle();

    expect(find.text('Estrelas: 1'), findsOneWidget);
    expect(find.textContaining('Refazer Pressionar a tecla A'), findsOneWidget);
    semantics.dispose();
  });
}
