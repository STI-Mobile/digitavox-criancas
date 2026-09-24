import 'audio_cue.dart';

/// Public boundary used by cue producers. Platform details remain behind the
/// concrete coordinator and its injected services.
abstract interface class AudioGuidance {
  Future<void> play(AudioCue cue);

  Future<void> playSequence(Iterable<AudioCue> cues);

  Future<void> stop();

  Future<void> cancelSequence();

  Future<void> dispose();
}
