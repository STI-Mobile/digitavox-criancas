import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/application/audio/audio_guidance_coordinator.dart';
import 'src/data/persistence/local_progress_repository.dart';
import 'src/data/persistence/shared_preferences_progress_store.dart';
import 'src/infrastructure/audio/audioplayers_guidance_player.dart';
import 'src/infrastructure/audio/debug_audio_guidance_logger.dart';
import 'src/infrastructure/audio/platform_text_to_speech_service.dart';
import 'src/infrastructure/content/asset_course_catalog.dart';
import 'src/infrastructure/content/development_course_catalog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DigitavoxApp(
      courseCatalog: const DevelopmentCourseCatalog(
        enabled: kDebugMode,
        demoCatalog: AssetCourseCatalog(
          assetPath: 'assets/content/integration_demo_course.json',
        ),
      ),
      progressRepository: LocalProgressRepository(
        store: SharedPreferencesProgressStore(),
      ),
      audioGuidance: AudioGuidanceCoordinator(
        textToSpeechService: PlatformTextToSpeechService(),
        speechAssetPlayer: AudioplayersGuidancePlayer(),
        sfxPlayer: AudioplayersGuidancePlayer(),
        musicPlayer: AudioplayersGuidancePlayer(),
        logger: const DebugAudioGuidanceLogger(),
      ),
    ),
  );
}
