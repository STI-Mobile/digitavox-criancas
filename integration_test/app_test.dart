import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/data/persistence/local_progress_repository.dart';
import 'package:digitavox_criancas/src/data/persistence/shared_preferences_progress_store.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/recording_audio_guidance.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads the bundled demo catalog', (tester) async {
    await tester.pumpWidget(
      DigitavoxApp(
        courseCatalog: const AssetCourseCatalog(
          assetPath: 'assets/content/demo_course.json',
        ),
        progressRepository: InMemoryProgressRepository(),
        audioGuidance: RecordingAudioGuidance(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Exploradores Espaciais'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);
  });

  testWidgets('restores progress after recreating the app', (tester) async {
    final preferences = SharedPreferencesAsync();
    final previousDocument = await preferences.getString(
      SharedPreferencesProgressStore.storageKey,
    );
    await preferences.remove(SharedPreferencesProgressStore.storageKey);
    addTearDown(() async {
      if (previousDocument == null) {
        await preferences.remove(SharedPreferencesProgressStore.storageKey);
      } else {
        await preferences.setString(
          SharedPreferencesProgressStore.storageKey,
          previousDocument,
        );
      }
    });

    await tester.pumpWidget(_persistentApp(preferences));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Começar curso'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 3; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar à lição'));
    await tester.pumpAndSettle();
    final backToCourse = find.widgetWithText(TextButton, 'Voltar ao curso');
    await tester.ensureVisible(backToCourse);
    await tester.pumpAndSettle();
    await tester.tap(backToCourse);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('1 estrelas conquistadas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_persistentApp(SharedPreferencesAsync()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('1 estrelas conquistadas'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Continuar curso'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar curso'));
    await tester.pumpAndSettle();
    expect(find.text('Tecla J'), findsOneWidget);
  });
}

DigitavoxApp _persistentApp(SharedPreferencesAsync preferences) {
  return DigitavoxApp(
    courseCatalog: const AssetCourseCatalog(
      assetPath: 'assets/content/demo_course.json',
    ),
    progressRepository: LocalProgressRepository(
      store: SharedPreferencesProgressStore(preferences: preferences),
    ),
    audioGuidance: RecordingAudioGuidance(),
  );
}
