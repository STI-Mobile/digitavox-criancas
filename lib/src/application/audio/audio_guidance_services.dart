final class SpeechConfiguration {
  const SpeechConfiguration({
    this.locale = 'pt-BR',
    this.rate = 0.85,
    this.pitch = 1,
    this.volume = 1,
    this.voice,
  });

  final String locale;
  final double rate;
  final double pitch;
  final double volume;
  final String? voice;
}

final class AudioGuidanceConfiguration {
  const AudioGuidanceConfiguration({
    this.speechAssetVolume = 1,
    this.sfxVolume = 1,
    this.musicVolume = 0.6,
  });

  final double speechAssetVolume;
  final double sfxVolume;
  final double musicVolume;
}

abstract interface class TextToSpeechService {
  Future<void> initialize(SpeechConfiguration configuration);

  /// Completes when the utterance finishes or is stopped.
  Future<void> speak(String text);

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class AssetAudioPlayer {
  /// Completes when playback finishes or is stopped.
  Future<void> play(String asset);

  Future<void> setVolume(double volume);

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class SfxPlayer {
  Future<void> play(String asset);

  Future<void> setVolume(double volume);

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class MusicPlayer {
  Future<void> play(String asset);

  Future<void> pause();

  Future<void> setVolume(double volume);

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class AudioGuidanceLogger {
  void log(String event);
}

final class SilentAudioGuidanceLogger implements AudioGuidanceLogger {
  const SilentAudioGuidanceLogger();

  @override
  void log(String event) {}
}

class AudioGuidanceException implements Exception {
  const AudioGuidanceException(this.message);

  final String message;

  @override
  String toString() => 'AudioGuidanceException: $message';
}

final class InvalidAudioCueException extends AudioGuidanceException {
  const InvalidAudioCueException(super.message);
}

final class AudioGuidanceDisposedException extends AudioGuidanceException {
  const AudioGuidanceDisposedException()
    : super('O Audio Guidance já foi descartado.');
}

final class AudioServiceException extends AudioGuidanceException {
  const AudioServiceException({required this.operation, required this.cause})
    : super('Falha no serviço durante $operation.');

  final String operation;
  final Object cause;
}
