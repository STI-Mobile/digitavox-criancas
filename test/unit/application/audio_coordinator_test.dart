import 'package:digitavox_criancas/src/application/audio/audio_coordinator.dart';
import 'package:digitavox_criancas/src/application/audio/content_audio_service.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_content_audio_service.dart';

void main() {
  const firstAudio = ContentAudioReference(
    assetPath: 'assets/audio/demo/first.wav',
  );
  const secondAudio = ContentAudioReference(
    assetPath: 'assets/audio/demo/second.wav',
  );

  test('stops current content before starting a new narration', () async {
    final service = FakeContentAudioService();
    final coordinator = AudioCoordinator(contentAudioService: service);

    await coordinator.playContent(firstAudio);
    await coordinator.playContent(secondAudio);

    expect(service.events, <String>[
      'stop',
      'play:assets/audio/demo/first.wav',
      'stop',
      'play:assets/audio/demo/second.wav',
    ]);
  });

  test('supersedes a queued narration before it can start', () async {
    final service = FakeContentAudioService();
    final coordinator = AudioCoordinator(contentAudioService: service);

    final firstRequest = coordinator.playContent(firstAudio);
    final secondRequest = coordinator.playContent(secondAudio);
    await Future.wait(<Future<void>>[firstRequest, secondRequest]);

    expect(service.events, <String>[
      'stop',
      'stop',
      'play:assets/audio/demo/second.wav',
    ]);
  });

  test('supports explicit stop and releases the service on dispose', () async {
    final service = FakeContentAudioService();
    final coordinator = AudioCoordinator(contentAudioService: service);

    await coordinator.playContent(firstAudio);
    await coordinator.stop();
    await coordinator.dispose();

    expect(service.events, <String>[
      'stop',
      'play:assets/audio/demo/first.wav',
      'stop',
      'stop',
      'dispose',
    ]);
  });

  test(
    'records a known playback failure without breaking the caller',
    () async {
      final service = FakeContentAudioService()
        ..playFailure = const ContentAudioPlaybackException(
          operation: 'iniciar reprodução',
          cause: 'asset ausente',
        );
      final coordinator = AudioCoordinator(contentAudioService: service);

      await coordinator.playContent(firstAudio);

      expect(coordinator.lastFailure, same(service.playFailure));
      expect(service.events, <String>[
        'stop',
        'play:assets/audio/demo/first.wav',
      ]);
    },
  );
}
