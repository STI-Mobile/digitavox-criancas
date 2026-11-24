import 'package:digitavox_criancas/src/data/persistence/local_profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
import 'src/app_environment.dart';
import 'src/application/audio/audio_guidance_coordinator.dart';
import 'src/data/persistence/shared_preferences_progress_store.dart';
import 'src/infrastructure/audio/audioplayers_guidance_player.dart';
import 'src/infrastructure/audio/debug_audio_guidance_logger.dart';
import 'src/infrastructure/audio/platform_text_to_speech_service.dart';
import 'src/infrastructure/content/asset_course_catalog.dart';
import 'src/infrastructure/content/development_course_catalog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = AppEnvironment.fromBuild(
    isDebugBuild: kDebugMode,
    flavor: appFlavor,
  );

  final profileStore = SharedPreferencesProgressStore(
    storageKey: 'digitavox.profiles',
  );

  runApp(
    DigitavoxApp(
      courseCatalog: createCourseCatalogForEnvironment(environment),
      profileRepository: LocalProfileRepository(
        profilesStore: profileStore,
        progressStoreFor: (profileId) => SharedPreferencesProgressStore(
          storageKey: 'digitavox.progress.$profileId',
        ),
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

DevelopmentCourseCatalog createCourseCatalogForEnvironment(
  AppEnvironment environment,
) => DevelopmentCourseCatalog(
  enabled: environment.exposesTechnicalDemo,
  demoCatalog: AssetCourseCatalog(
    assetPath: 'assets/content/exploradores_espaciais.json',
  ),
);
