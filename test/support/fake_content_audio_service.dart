import 'package:digitavox_criancas/src/application/audio/content_audio_service.dart';

final class FakeContentAudioService implements ContentAudioService {
  final List<String> events = <String>[];

  ContentAudioPlaybackException? playFailure;
  ContentAudioPlaybackException? stopFailure;
  ContentAudioPlaybackException? disposeFailure;

  @override
  Future<void> playAsset(String assetPath) async {
    events.add('play:$assetPath');
    final failure = playFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> stop() async {
    events.add('stop');
    final failure = stopFailure;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
    final failure = disposeFailure;
    if (failure != null) {
      throw failure;
    }
  }
}
