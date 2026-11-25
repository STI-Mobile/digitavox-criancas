import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:digitavox_criancas/src/presentation/design_system/app_theme/dvx_app_theme.dart';
import 'package:digitavox_criancas/src/presentation/design_system/components/dvx_game_components.dart';
import 'package:digitavox_criancas/src/presentation/design_system/course_theme/course_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps text and control colors at WCAG AA contrast', () {
    for (final preference in AppThemePreference.values) {
      final scheme = DvxAppTheme.resolve(preference).colorScheme;

      expect(
        _contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(scheme.onSecondary, scheme.secondary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(scheme.onError, scheme.error),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('renders every feedback state with text and an icon', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.standard),
        home: DvxGameScaffold(
          courseTheme: const NeutralCourseTheme().resolve(
            AppThemePreference.standard,
          ),
          title: 'Teste',
          body: const Column(
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
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.dark),
        home: DvxGameScaffold(
          courseTheme: const NeutralCourseTheme().resolve(
            AppThemePreference.dark,
          ),
          title: 'Teste',
          body: const DvxKeyPrompt(
            value: 'ASDFG',
            nextCharacter: 'a',
            inputIndex: 0,
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Exercício: ASDFG. Próxima tecla: a.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grays typed keys and waits for space after the target', (
    tester,
  ) async {
    const courseTheme = NeutralCourseTheme();
    Widget prompt({required int inputIndex, required String nextCharacter}) =>
        MaterialApp(
          theme: DvxAppTheme.resolve(AppThemePreference.standard),
          home: DvxGameScaffold(
            courseTheme: courseTheme.resolve(AppThemePreference.standard),
            title: 'Teste',
            body: DvxKeyPrompt(
              value: 'ASDFG',
              nextCharacter: nextCharacter,
              inputIndex: inputIndex,
            ),
          ),
        );

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(prompt(inputIndex: 1, nextCharacter: 's'));
    await tester.pumpAndSettle();

    final activeLetters = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => text.data?.length == 1 && 'ASDFG'.contains(text.data!))
        .toList();
    expect(activeLetters.first.style!.color, const Color(0xFF757575));
    expect(activeLetters[1].data, 'S');
    final activeLines = tester
        .widgetList<Container>(find.byType(Container))
        .where((container) => container.constraints?.maxHeight == 5)
        .toList();
    expect(
      (activeLines[1].decoration as BoxDecoration).color,
      courseTheme.resolve(AppThemePreference.standard).resolvedSuccess,
    );
    expect(
      find.bySemanticsLabel('Exercício: ASDFG. Próxima tecla: s.'),
      findsOneWidget,
    );

    await tester.pumpWidget(prompt(inputIndex: 5, nextCharacter: ' '));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .where(
            (text) => text.data?.length == 1 && 'ASDFG'.contains(text.data!),
          )
          .every((text) => text.style!.color == const Color(0xFF757575)),
      isTrue,
    );
    expect(
      tester
          .widgetList<Container>(find.byType(Container))
          .where((container) => container.constraints?.maxHeight == 5)
          .every(
            (container) =>
                (container.decoration as BoxDecoration).color ==
                Colors.transparent,
          ),
      isTrue,
    );
    expect(
      find.bySemanticsLabel(
        'Exercício: ASDFG. Próxima tecla: barra de espaço.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('blinks only the active key underline', (tester) async {
    const courseTheme = NeutralCourseTheme();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: DvxAppTheme.resolve(AppThemePreference.standard),
        home: DvxGameScaffold(
          courseTheme: courseTheme.resolve(AppThemePreference.standard),
          title: 'Teste',
          body: const DvxKeyPrompt(
            value: 'ASDFG',
            nextCharacter: 'a',
            inputIndex: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    final underline = find.byKey(
      const ValueKey<String>('active-key-underline'),
    );
    final initialOpacity = tester
        .widget<FadeTransition>(underline)
        .opacity
        .value;
    await tester.pump(const Duration(milliseconds: 300));
    final nextOpacity = tester.widget<FadeTransition>(underline).opacity.value;

    expect(nextOpacity, isNot(initialOpacity));
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

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}
