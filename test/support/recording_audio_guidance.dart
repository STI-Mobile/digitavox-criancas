import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
import 'package:digitavox_criancas/src/application/audio/audio_guidance.dart';
import 'package:digitavox_criancas/src/application/audio/audio_guidance_services.dart';

final class RecordingAudioGuidance implements AudioGuidance {
  final List<String> events = <String>[];
  final List<List<AudioCue>> sequences = <List<AudioCue>>[];
  bool disposed = false;
  AudioGuidanceException? playFailure;

  Iterable<AudioCue> get playedCues => sequences.expand((cues) => cues);

  @override
  Future<void> play(AudioCue cue) async {
    events.add('play:${cue.id}');
    final failure = playFailure;
    if (failure != null) throw failure;
    sequences.add(<AudioCue>[cue]);
  }

  @override
  Future<void> playSequence(Iterable<AudioCue> cues) async {
    final sequence = List<AudioCue>.unmodifiable(cues);
    events.add('sequence:${sequence.map((cue) => cue.id).join(',')}');
    final failure = playFailure;
    if (failure != null) throw failure;
    sequences.add(sequence);
  }

  @override
  Future<void> stop() async {
    events.add('stop');
  }

  @override
  Future<void> cancelSequence() async {
    events.add('cancel');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
    disposed = true;
  }
}
