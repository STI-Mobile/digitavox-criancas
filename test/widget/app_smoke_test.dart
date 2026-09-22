import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts, exposes demo content, and records completion', (
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
      find.widgetWithText(ElevatedButton, 'Localizar a tecla F'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Estrelas: 1'), findsOneWidget);
    expect(
      find.textContaining('Localizar a tecla F — concluído'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Localizar a tecla F.*Concluído')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
