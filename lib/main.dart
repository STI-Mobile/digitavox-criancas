import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/application/audio/audio_coordinator.dart';
import 'src/data/persistence/local_progress_repository.dart';
import 'src/data/persistence/shared_preferences_progress_store.dart';
import 'src/infrastructure/audio/audioplayers_content_audio_service.dart';
import 'src/infrastructure/content/asset_course_catalog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DigitavoxApp(
      courseCatalog: const AssetCourseCatalog(
        assetPath: 'assets/content/demo_course.json',
      ),
      progressRepository: LocalProgressRepository(
        store: SharedPreferencesProgressStore(),
      ),
      audioCoordinator: AudioCoordinator(
        contentAudioService: AudioplayersContentAudioService(),
      ),
    ),
  );
}
