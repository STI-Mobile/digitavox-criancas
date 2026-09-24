import 'dart:async';

import 'package:digitavox_criancas/src/application/audio/audio_guidance_services.dart';

final class FakeTextToSpeechService implements TextToSpeechService {
  FakeTextToSpeechService({List<String>? events})
    : events = events ?? <String>[];

  final List<String> events;
  SpeechConfiguration? configuration;
  bool autoComplete = true;
  bool disposed = false;
  Object? initializeFailure;
  Object? speakFailure;
  Completer<void>? _activeSpeech;

  @override
  Future<void> initialize(SpeechConfiguration configuration) async {
    events.add('tts.initialize');
    this.configuration = configuration;
    final failure = initializeFailure;
    if (failure != null) {
      throw AudioServiceException(operation: 'initialize', cause: failure);
    }
  }

  @override
  Future<void> speak(String text) async {
    events.add('tts.speak:$text');
    final failure = speakFailure;
    if (failure != null) {
      throw AudioServiceException(operation: 'speak', cause: failure);
    }
    if (!autoComplete) {
      _activeSpeech = Completer<void>();
      await _activeSpeech!.future;
    }
  }

  @override
  Future<void> stop() async {
    events.add('tts.stop');
    completeSpeech();
  }

  @override
  Future<void> dispose() async {
    events.add('tts.dispose');
    disposed = true;
    completeSpeech();
  }

  void completeSpeech() {
    final activeSpeech = _activeSpeech;
    _activeSpeech = null;
    if (activeSpeech != null && !activeSpeech.isCompleted) {
      activeSpeech.complete();
    }
  }
}

final class FakeAssetAudioPlayer implements AssetAudioPlayer {
  FakeAssetAudioPlayer({List<String>? events}) : events = events ?? <String>[];

  final List<String> events;
  final Set<String> failingAssets = <String>{};
  bool autoComplete = true;
  bool disposed = false;
  Completer<void>? _activePlayback;

  @override
  Future<void> play(String asset) async {
    events.add('asset.play:$asset');
    if (failingAssets.contains(asset)) {
      throw AudioServiceException(operation: 'play', cause: asset);
    }
    if (!autoComplete) {
      _activePlayback = Completer<void>();
      await _activePlayback!.future;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    events.add('asset.volume:$volume');
  }

  @override
  Future<void> stop() async {
    events.add('asset.stop');
    completePlayback();
  }

  @override
  Future<void> dispose() async {
    events.add('asset.dispose');
    disposed = true;
    completePlayback();
  }

  void completePlayback() {
    final activePlayback = _activePlayback;
    _activePlayback = null;
    if (activePlayback != null && !activePlayback.isCompleted) {
      activePlayback.complete();
    }
  }
}

final class FakeSfxPlayer implements SfxPlayer {
  FakeSfxPlayer({List<String>? events}) : events = events ?? <String>[];

  final List<String> events;
  final Set<String> failingAssets = <String>{};
  bool autoComplete = true;
  bool disposed = false;
  Completer<void>? _activePlayback;

  @override
  Future<void> play(String asset) async {
    events.add('sfx.play:$asset');
    if (failingAssets.contains(asset)) {
      throw AudioServiceException(operation: 'play', cause: asset);
    }
    if (!autoComplete) {
      _activePlayback = Completer<void>();
      await _activePlayback!.future;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    events.add('sfx.volume:$volume');
  }

  @override
  Future<void> stop() async {
    events.add('sfx.stop');
    _completePlayback();
  }

  @override
  Future<void> dispose() async {
    events.add('sfx.dispose');
    disposed = true;
    _completePlayback();
  }

  void _completePlayback() {
    final activePlayback = _activePlayback;
    _activePlayback = null;
    if (activePlayback != null && !activePlayback.isCompleted) {
      activePlayback.complete();
    }
  }
}

final class FakeMusicPlayer implements MusicPlayer {
  FakeMusicPlayer({List<String>? events}) : events = events ?? <String>[];

  final List<String> events;
  bool disposed = false;

  @override
  Future<void> play(String asset) async {
    events.add('music.play:$asset');
  }

  @override
  Future<void> pause() async {
    events.add('music.pause');
  }

  @override
  Future<void> setVolume(double volume) async {
    events.add('music.volume:$volume');
  }

  @override
  Future<void> stop() async {
    events.add('music.stop');
  }

  @override
  Future<void> dispose() async {
    events.add('music.dispose');
    disposed = true;
  }
}

final class FakeAudioGuidanceLogger implements AudioGuidanceLogger {
  final List<String> events = <String>[];

  @override
  void log(String event) => events.add(event);
}
