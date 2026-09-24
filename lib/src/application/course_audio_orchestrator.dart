import '../domain/content/course_catalog.dart';
import 'audio/audio_cue.dart';
import 'audio/audio_guidance.dart';
import 'audio/audio_guidance_services.dart';

/// Translates declarative course audio into generic cues. It knows course
/// events, but never knows players, TTS engines or platform APIs.
final class CourseAudioOrchestrator {
  factory CourseAudioOrchestrator({
    required AudioGuidance audioGuidance,
    AudioGuidanceLogger logger = const SilentAudioGuidanceLogger(),
  }) => CourseAudioOrchestrator._(audioGuidance, logger);

  const CourseAudioOrchestrator._(this._audioGuidance, this._logger);

  final AudioGuidance _audioGuidance;
  final AudioGuidanceLogger _logger;

  List<AudioCue> resolve(
    CourseAudioConfiguration? configuration,
    CourseAudioEvent event,
  ) {
    final declaredCues = configuration?.cuesFor(event);
    if (declaredCues == null || declaredCues.isEmpty) {
      return const <AudioCue>[];
    }

    return List<AudioCue>.unmodifiable(
      declaredCues.map(
        (cue) => switch (cue.type) {
          ContentAudioCueType.speech => SpeechCue(
            id: cue.id,
            text: cue.text ?? '',
            audioAsset: cue.asset,
            speaker: cue.speaker,
          ),
          ContentAudioCueType.sfx => SfxCue(id: cue.id, asset: cue.asset!),
          ContentAudioCueType.music => MusicCue(id: cue.id, asset: cue.asset!),
        },
      ),
    );
  }

  bool hasCues(
    CourseAudioConfiguration? configuration,
    CourseAudioEvent event,
  ) => configuration?.cuesFor(event).isNotEmpty == true;

  Future<void> play(
    CourseAudioConfiguration? configuration,
    CourseAudioEvent event,
  ) async {
    final cues = resolve(configuration, event);
    if (cues.isEmpty) {
      _logger.log('course_audio_event_unconfigured');
      await _audioGuidance.stop();
      return;
    }

    _logger.log('course_audio_event_resolved');
    try {
      await _audioGuidance.playSequence(cues);
    } on AudioGuidanceException {
      _logger.log('audio_service_unavailable');
    }
  }

  Future<void> cancel() async {
    _logger.log('course_audio_cancelled');
    await _audioGuidance.cancelSequence();
  }
}
