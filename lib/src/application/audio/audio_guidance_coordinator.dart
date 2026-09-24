import 'audio_cue.dart';
import 'audio_guidance.dart';
import 'audio_guidance_services.dart';

/// Executes generic audio cues. Cue producers decide what and when; this class
/// decides how, including speech asset-to-TTS fallback and sequencing.
final class AudioGuidanceCoordinator implements AudioGuidance {
  factory AudioGuidanceCoordinator({
    required TextToSpeechService textToSpeechService,
    required AssetAudioPlayer speechAssetPlayer,
    required SfxPlayer sfxPlayer,
    required MusicPlayer musicPlayer,
    SpeechConfiguration speechConfiguration = const SpeechConfiguration(),
    AudioGuidanceConfiguration audioConfiguration =
        const AudioGuidanceConfiguration(),
    AudioGuidanceLogger logger = const SilentAudioGuidanceLogger(),
  }) => AudioGuidanceCoordinator._(
    textToSpeechService,
    speechAssetPlayer,
    sfxPlayer,
    musicPlayer,
    speechConfiguration,
    audioConfiguration,
    logger,
  );

  AudioGuidanceCoordinator._(
    this._textToSpeechService,
    this._speechAssetPlayer,
    this._sfxPlayer,
    this._musicPlayer,
    this.speechConfiguration,
    this.audioConfiguration,
    this.logger,
  );

  final TextToSpeechService _textToSpeechService;
  final AssetAudioPlayer _speechAssetPlayer;
  final SfxPlayer _sfxPlayer;
  final MusicPlayer _musicPlayer;
  final SpeechConfiguration speechConfiguration;
  final AudioGuidanceConfiguration audioConfiguration;
  final AudioGuidanceLogger logger;

  var _generation = 0;
  var _ttsInitialized = false;
  var _disposed = false;

  bool get isDisposed => _disposed;

  @override
  Future<void> play(AudioCue cue) async {
    _ensureActive();
    _validate(cue);
    final generation = ++_generation;
    await _stopPlayers();
    if (!_isCurrent(generation)) return;
    await _playCue(cue, generation);
  }

  @override
  Future<void> playSequence(Iterable<AudioCue> cues) async {
    _ensureActive();
    final sequence = List<AudioCue>.unmodifiable(cues);
    for (final cue in sequence) {
      _validate(cue);
    }

    final generation = ++_generation;
    await _stopPlayers();
    for (final cue in sequence) {
      if (!_isCurrent(generation)) return;
      await _playCue(cue, generation);
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    ++_generation;
    await _stopPlayers();
  }

  @override
  Future<void> cancelSequence() async {
    if (_disposed) return;
    ++_generation;
    logger.log('audio_sequence_cancelled');
    await _stopPlayers();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    await _stopPlayers();
    await Future.wait<void>([
      _guardService(_speechAssetPlayer.dispose),
      _guardService(_sfxPlayer.dispose),
      _guardService(_musicPlayer.dispose),
      _guardService(_textToSpeechService.dispose),
    ]);
  }

  Future<void> _playCue(AudioCue cue, int generation) => switch (cue) {
    SpeechCue() => _playSpeech(cue, generation),
    SfxCue() => _playSfx(cue),
    MusicCue() => _playMusic(cue),
  };

  Future<void> _playSpeech(SpeechCue cue, int generation) async {
    final asset = cue.audioAsset?.trim();
    if (asset != null && asset.isNotEmpty) {
      try {
        await _speechAssetPlayer.setVolume(
          audioConfiguration.speechAssetVolume,
        );
        await _speechAssetPlayer.play(asset);
        return;
      } on AudioServiceException {
        logger.log('audio_asset_failed');
      }
    }

    if (!_isCurrent(generation)) return;
    final text = cue.text.trim();
    if (text.isEmpty) {
      throw const InvalidAudioCueException(
        'SpeechCue precisa de texto quando o asset não pode ser reproduzido.',
      );
    }

    if (asset != null && asset.isNotEmpty) {
      logger.log('audio_tts_fallback');
    }
    await _initializeTts();
    if (!_isCurrent(generation)) return;
    await _textToSpeechService.speak(text);
  }

  Future<void> _playSfx(SfxCue cue) async {
    await _sfxPlayer.setVolume(audioConfiguration.sfxVolume);
    await _sfxPlayer.play(cue.asset);
  }

  Future<void> _playMusic(MusicCue cue) async {
    await _musicPlayer.setVolume(audioConfiguration.musicVolume);
    await _musicPlayer.play(cue.asset);
  }

  Future<void> _initializeTts() async {
    if (_ttsInitialized) return;
    try {
      await _textToSpeechService.initialize(speechConfiguration);
      _ttsInitialized = true;
    } on AudioServiceException {
      logger.log('audio_service_unavailable');
      rethrow;
    }
  }

  Future<void> _stopPlayers() => Future.wait<void>([
    _guardService(_speechAssetPlayer.stop),
    _guardService(_sfxPlayer.stop),
    _guardService(_musicPlayer.stop),
    _guardService(_textToSpeechService.stop),
  ]);

  Future<void> _guardService(Future<void> Function() operation) async {
    try {
      await operation();
    } on AudioServiceException {
      logger.log('audio_service_unavailable');
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _ensureActive() {
    if (_disposed) throw const AudioGuidanceDisposedException();
  }

  void _validate(AudioCue cue) {
    if (cue.id.trim().isEmpty) {
      throw const InvalidAudioCueException('AudioCue.id não pode ser vazio.');
    }
    switch (cue) {
      case SpeechCue(:final text, :final audioAsset):
        if (text.trim().isEmpty &&
            (audioAsset == null || audioAsset.trim().isEmpty)) {
          throw const InvalidAudioCueException(
            'SpeechCue precisa de texto ou audioAsset.',
          );
        }
      case SfxCue(:final asset) || MusicCue(:final asset):
        if (asset.trim().isEmpty) {
          throw const InvalidAudioCueException(
            'O asset do cue não pode ser vazio.',
          );
        }
    }
  }
}
