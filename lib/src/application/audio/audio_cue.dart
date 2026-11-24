sealed class AudioCue {
  const AudioCue({required this.id});

  final String id;
}

final class SpeechCue extends AudioCue {
  const SpeechCue({
    required super.id,
    required this.text,
    this.audioAsset,
    this.speaker,
  });

  final String text;
  final String? audioAsset;

  /// Opaque metadata owned by the cue producer, not interpreted by guidance.
  final String? speaker;
}

final class SfxCue extends AudioCue {
  const SfxCue({required super.id, required this.asset});

  final String asset;
}

/// A short system click, optionally repeated to distinguish two outcomes.
final class ClickCue extends AudioCue {
  const ClickCue({required super.id, this.doubleClick = false});

  final bool doubleClick;
}

final class MusicCue extends AudioCue {
  const MusicCue({required super.id, required this.asset});

  final String asset;
}
