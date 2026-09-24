import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
import 'package:digitavox_criancas/src/application/audio/audio_guidance_coordinator.dart';
import 'package:digitavox_criancas/src/application/audio/audio_guidance_services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_audio_guidance_services.dart';

void main() {
  group('AudioGuidanceCoordinator', () {
    late List<String> events;
    late FakeTextToSpeechService tts;
    late FakeAssetAudioPlayer assetPlayer;
    late FakeSfxPlayer sfxPlayer;
    late FakeMusicPlayer musicPlayer;
    late FakeAudioGuidanceLogger logger;
    late AudioGuidanceCoordinator coordinator;

    setUp(() {
      events = <String>[];
      tts = FakeTextToSpeechService(events: events);
      assetPlayer = FakeAssetAudioPlayer(events: events);
      sfxPlayer = FakeSfxPlayer(events: events);
      musicPlayer = FakeMusicPlayer(events: events);
      logger = FakeAudioGuidanceLogger();
      coordinator = AudioGuidanceCoordinator(
        textToSpeechService: tts,
        speechAssetPlayer: assetPlayer,
        sfxPlayer: sfxPlayer,
        musicPlayer: musicPlayer,
        logger: logger,
      );
    });

    test('reproduz SpeechCue por asset sem chamar TTS', () async {
      await coordinator.play(
        const SpeechCue(
          id: 'test-speech',
          text: 'Teste de áudio.',
          audioAsset: 'assets/audio/test.wav',
        ),
      );

      expect(events, contains('asset.play:assets/audio/test.wav'));
      expect(events.where((event) => event.startsWith('tts.speak:')), isEmpty);
    });

    test('usa TTS como fallback quando o asset de fala falha', () async {
      assetPlayer.failingAssets.add('assets/audio/missing.wav');

      await coordinator.play(
        const SpeechCue(
          id: 'test-speech',
          text: 'Teste de áudio.',
          audioAsset: 'assets/audio/missing.wav',
        ),
      );

      expect(events, contains('asset.play:assets/audio/missing.wav'));
      expect(events, contains('tts.speak:Teste de áudio.'));
      expect(
        logger.events,
        containsAllInOrder(<String>[
          'audio_asset_failed',
          'audio_tts_fallback',
        ]),
      );
    });

    test('reproduz SpeechCue somente textual com TTS', () async {
      await coordinator.play(
        const SpeechCue(id: 'test-speech', text: 'Teste de áudio.'),
      );

      expect(events, contains('tts.initialize'));
      expect(events, contains('tts.speak:Teste de áudio.'));
      expect(tts.configuration?.locale, 'pt-BR');
    });

    test('rejeita SpeechCue sem asset e sem texto', () async {
      await expectLater(
        coordinator.play(const SpeechCue(id: 'test-speech', text: '')),
        throwsA(isA<InvalidAudioCueException>()),
      );
    });

    test('reproduz SfxCue somente pelo SfxPlayer', () async {
      await coordinator.play(
        const SfxCue(id: 'test-sfx', asset: 'assets/audio/test.wav'),
      );

      expect(events, contains('sfx.play:assets/audio/test.wav'));
      expect(events.where((event) => event.startsWith('tts.speak:')), isEmpty);
    });

    test('executa uma sequência exatamente na ordem A, B e C', () async {
      await coordinator.playSequence(const <AudioCue>[
        SpeechCue(id: 'a', text: 'A'),
        SfxCue(id: 'b', asset: 'b.wav'),
        MusicCue(id: 'c', asset: 'c.wav'),
      ]);

      expect(_playEvents(events), <String>[
        'tts.speak:A',
        'sfx.play:b.wav',
        'music.play:c.wav',
      ]);
    });

    test('aguarda o fallback de B antes de iniciar C', () async {
      assetPlayer.failingAssets.add('b.wav');

      await coordinator.playSequence(const <AudioCue>[
        SpeechCue(id: 'a', text: 'A', audioAsset: 'a.wav'),
        SpeechCue(id: 'b', text: 'B', audioAsset: 'b.wav'),
        SfxCue(id: 'c', asset: 'c.wav'),
      ]);

      expect(_playEvents(events), <String>[
        'asset.play:a.wav',
        'asset.play:b.wav',
        'tts.speak:B',
        'sfx.play:c.wav',
      ]);
    });

    test('cancelSequence impede o início dos cues pendentes', () async {
      assetPlayer.autoComplete = false;
      final sequence = coordinator.playSequence(const <AudioCue>[
        SpeechCue(id: 'a', text: 'A', audioAsset: 'a.wav'),
        SpeechCue(id: 'b', text: 'B', audioAsset: 'b.wav'),
      ]);
      await _waitForEvent(events, 'asset.play:a.wav');

      await coordinator.cancelSequence();
      await sequence;

      expect(_playEvents(events), <String>['asset.play:a.wav']);
      expect(logger.events, contains('audio_sequence_cancelled'));
    });

    test('stop interrompe a reprodução atual', () async {
      assetPlayer.autoComplete = false;
      final playback = coordinator.play(
        const SpeechCue(
          id: 'test-speech',
          text: 'Teste de áudio.',
          audioAsset: 'test.wav',
        ),
      );
      await _waitForEvent(events, 'asset.play:test.wav');
      final stopsBefore = events.where((event) => event == 'asset.stop').length;

      await coordinator.stop();
      await playback;

      expect(
        events.where((event) => event == 'asset.stop').length,
        stopsBefore + 1,
      );
    });

    test(
      'sequência nova não recebe callbacks da sequência cancelada',
      () async {
        assetPlayer.autoComplete = false;
        final oldSequence = coordinator.playSequence(const <AudioCue>[
          SpeechCue(id: 'old-a', text: 'A', audioAsset: 'old-a.wav'),
          SpeechCue(id: 'old-b', text: 'B', audioAsset: 'old-b.wav'),
        ]);
        await _waitForEvent(events, 'asset.play:old-a.wav');

        await coordinator.cancelSequence();
        assetPlayer.autoComplete = true;
        final newSequence = coordinator.playSequence(const <AudioCue>[
          SpeechCue(id: 'new-a', text: 'D', audioAsset: 'new-a.wav'),
        ]);
        await Future.wait(<Future<void>>[oldSequence, newSequence]);

        expect(_playEvents(events), <String>[
          'asset.play:old-a.wav',
          'asset.play:new-a.wav',
        ]);
      },
    );

    test('dispose libera todos os recursos', () async {
      await coordinator.dispose();

      expect(assetPlayer.disposed, isTrue);
      expect(sfxPlayer.disposed, isTrue);
      expect(musicPlayer.disposed, isTrue);
      expect(tts.disposed, isTrue);
      expect(coordinator.isDisposed, isTrue);
    });

    test(
      'dispose interrompe sequência ativa e invalida cues pendentes',
      () async {
        assetPlayer.autoComplete = false;
        final sequence = coordinator.playSequence(const <AudioCue>[
          SpeechCue(id: 'a', text: 'A', audioAsset: 'a.wav'),
          SpeechCue(id: 'b', text: 'B', audioAsset: 'b.wav'),
        ]);
        await _waitForEvent(events, 'asset.play:a.wav');

        await coordinator.dispose();
        await sequence;

        expect(_playEvents(events), <String>['asset.play:a.wav']);
        expect(assetPlayer.disposed, isTrue);
        expect(tts.disposed, isTrue);
      },
    );

    test('play depois de dispose falha de forma controlada', () async {
      await coordinator.dispose();

      await expectLater(
        coordinator.play(const SpeechCue(id: 'test-speech', text: 'Teste')),
        throwsA(isA<AudioGuidanceDisposedException>()),
      );
    });

    test('falha de SFX não utiliza fallback TTS', () async {
      sfxPlayer.failingAssets.add('missing.wav');

      await expectLater(
        coordinator.play(const SfxCue(id: 'test-sfx', asset: 'missing.wav')),
        throwsA(isA<AudioServiceException>()),
      );

      expect(events.where((event) => event.startsWith('tts.speak:')), isEmpty);
    });

    test('metadata speaker não altera o mecanismo de reprodução', () async {
      await coordinator.play(
        const SpeechCue(
          id: 'test-speech',
          text: 'Teste de áudio.',
          audioAsset: 'test.wav',
          speaker: 'test-speaker',
        ),
      );

      expect(_playEvents(events), <String>['asset.play:test.wav']);
    });

    test('MusicCue usa a fronteira exclusiva de música', () async {
      await coordinator.play(
        const MusicCue(id: 'test-music', asset: 'music.wav'),
      );

      expect(_playEvents(events), <String>['music.play:music.wav']);
    });
  });
}

List<String> _playEvents(List<String> events) => events
    .where(
      (event) =>
          event.startsWith('asset.play:') ||
          event.startsWith('tts.speak:') ||
          event.startsWith('sfx.play:') ||
          event.startsWith('music.play:'),
    )
    .toList();

Future<void> _waitForEvent(List<String> events, String expected) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (events.contains(expected)) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Evento não observado: $expected. Eventos: $events');
}
