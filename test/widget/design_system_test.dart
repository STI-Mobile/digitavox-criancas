import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:digitavox_criancas/src/presentation/design_system/app_theme/dvx_app_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/components/dvx_game_components.dart';
import 'package:digitavox_criancas/src/presentation/design_system/course_theme/course_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders every feedback state with text and an icon', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.standard),
        home: const Scaffold(
          body: Column(
            children: [
              DvxFeedback(
                kind: DvxFeedbackKind.waiting,
                message: 'Aguardando entrada.',
              ),
              DvxFeedback(
                kind: DvxFeedbackKind.error,
                message: 'Tecla incorreta.',
              ),
              DvxFeedback(
                kind: DvxFeedbackKind.success,
                message: 'Resposta correta.',
              ),
              DvxFeedback(
                kind: DvxFeedbackKind.completed,
                message: 'Exercício concluído.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Aguardando entrada.'), findsOneWidget);
    expect(find.bySemanticsLabel('Tecla incorreta.'), findsOneWidget);
    expect(find.bySemanticsLabel('Resposta correta.'), findsOneWidget);
    expect(find.bySemanticsLabel('Exercício concluído.'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keeps the key prompt usable with enlarged text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.dark),
        home: const Scaffold(
          body: DvxKeyPrompt(value: 'ASDFG', nextCharacter: 'a'),
        ),
      ),
    );

    expect(find.text('ASDFG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removes decorative stars in High Contrast', (tester) async {
    const courseTheme = SpaceCourseTheme();
    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.highContrast),
        home: DvxGameScaffold(
          courseTheme: courseTheme.resolve(AppThemePreference.highContrast),
          title: 'Exercício',
          body: const Text('Conteúdo'),
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.text('Conteúdo'), findsOneWidget);
  });
}
