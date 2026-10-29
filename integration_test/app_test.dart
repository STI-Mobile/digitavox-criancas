import 'dart:convert';

import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/data/persistence/local_profile_repository.dart';
import 'package:digitavox_criancas/src/data/persistence/shared_preferences_progress_store.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/recording_audio_guidance.dart';

const _profilesKey = 'digitavox.integration.profiles';
const _progressKey = 'digitavox.integration.progress.cadete';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'restores a profile and completed exercise after recreating the app',
    (tester) async {
      final preferences = SharedPreferencesAsync();
      final previous = <String, String?>{};
      for (final key in [_profilesKey, _progressKey]) {
        previous[key] = await preferences.getString(key);
        await preferences.remove(key);
      }
      addTearDown(() async {
        for (final entry in previous.entries) {
          if (entry.value == null) {
            await preferences.remove(entry.key);
          } else {
            await preferences.setString(entry.key, entry.value!);
          }
        }
      });
      await preferences.setString(
        _profilesKey,
        jsonEncode([
          {'id': 'cadete', 'name': 'Cadete de teste'},
        ]),
      );
      await tester.pumpWidget(_persistentApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cadete de teste'));
      await tester.pumpAndSettle();
      expect(find.text('DEMO'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Começar curso'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Começar missão'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF, character: 'f');
        await tester.pumpAndSettle();
      }
      expect(find.text('Exercício concluído!'), findsOneWidget);
      expect(await preferences.getString(_progressKey), isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(_persistentApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cadete de teste'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar curso'));
      await tester.pumpAndSettle();
      expect(find.text('Sensores da Aurora'), findsWidgets);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar missão'));
      await tester.pumpAndSettle();
      expect(find.text('J'), findsOneWidget);
      expect(find.text('Exercício 2 de 2'), findsOneWidget);
    },
  );
}

DigitavoxApp _persistentApp() => DigitavoxApp(
  courseCatalog: const AssetCourseCatalog(
    assetPath: 'assets/content/demo_course.json',
  ),
  profileRepository: LocalProfileRepository(
    profilesStore: SharedPreferencesProgressStore(storageKey: _profilesKey),
    progressStoreFor: (_) =>
        SharedPreferencesProgressStore(storageKey: _progressKey),
  ),
  audioGuidance: RecordingAudioGuidance(),
);
