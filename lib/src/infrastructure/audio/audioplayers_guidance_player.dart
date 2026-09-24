import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../application/audio/audio_guidance_services.dart';

/// A completion-aware asset player. Separate instances are injected for
/// speech assets, SFX and music even though they share this implementation.
final class AudioplayersGuidancePlayer
    implements AssetAudioPlayer, SfxPlayer, MusicPlayer {
  AudioplayersGuidancePlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    _completionSubscription = _player.onPlayerComplete.listen((_) {
      final active = _activeCompletion;
      _activeCompletion = null;
      if (active != null && !active.isCompleted) active.complete();
    });
  }

  static final AudioContext _audioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  final AudioPlayer _player;
  late final StreamSubscription<void> _completionSubscription;
  Completer<void>? _activeCompletion;
  var _generation = 0;
  var _disposed = false;

  @override
  Future<void> play(String asset) async {
    if (_disposed) {
      throw const AudioServiceException(
        operation: 'play',
        cause: 'player descartado',
      );
    }

    final generation = ++_generation;
    await _guard('stop', _stopPlayer);
    final completion = Completer<void>();
    _activeCompletion = completion;

    try {
      final packageAsset = asset.startsWith('assets/')
          ? asset.substring('assets/'.length)
          : asset;
      await _player.play(
        AssetSource(packageAsset),
        ctx: _audioContext,
        mode: PlayerMode.mediaPlayer,
      );
      if (_disposed || generation != _generation) {
        await _stopPlayer();
        return;
      }
      await completion.future;
    } on PlatformException catch (error) {
      _completeActive();
      throw AudioServiceException(operation: 'play', cause: error);
    } on TimeoutException catch (error) {
      _completeActive();
      throw AudioServiceException(operation: 'play', cause: error);
    } on FlutterError catch (error) {
      _completeActive();
      throw AudioServiceException(operation: 'play', cause: error);
    } on Exception catch (error) {
      _completeActive();
      throw AudioServiceException(operation: 'play', cause: error);
    }
  }

  @override
  Future<void> pause() => _guard('pause', _player.pause);

  @override
  Future<void> setVolume(double volume) =>
      _guard('setVolume', () => _player.setVolume(volume.clamp(0, 1)));

  @override
  Future<void> stop() async {
    if (_disposed) return;
    ++_generation;
    await _guard('stop', _stopPlayer);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    ++_generation;
    await _guard('stop', _stopPlayer);
    _disposed = true;
    await _completionSubscription.cancel();
    await _guard('dispose', _player.dispose);
  }

  Future<void> _stopPlayer() async {
    await _player.stop();
    _completeActive();
  }

  void _completeActive() {
    final active = _activeCompletion;
    _activeCompletion = null;
    if (active != null && !active.isCompleted) active.complete();
  }

  Future<void> _guard(String operation, Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (error) {
      throw AudioServiceException(operation: operation, cause: error);
    } on TimeoutException catch (error) {
      throw AudioServiceException(operation: operation, cause: error);
    } on FlutterError catch (error) {
      throw AudioServiceException(operation: operation, cause: error);
    } on Exception catch (error) {
      throw AudioServiceException(operation: operation, cause: error);
    }
  }
}
