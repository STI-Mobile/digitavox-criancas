import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../application/audio/content_audio_service.dart';

final class AudioplayersContentAudioService implements ContentAudioService {
  AudioplayersContentAudioService({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  static final AudioContext _audioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.speech,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  final AudioPlayer _player;

  @override
  Future<void> playAsset(String assetPath) => _guard(
    operation: 'iniciar reprodução',
    action: () {
      final packageAssetPath = assetPath.startsWith('assets/')
          ? assetPath.substring('assets/'.length)
          : assetPath;
      return _player.play(
        AssetSource(packageAssetPath),
        ctx: _audioContext,
        mode: PlayerMode.mediaPlayer,
      );
    },
  );

  @override
  Future<void> stop() =>
      _guard(operation: 'interromper reprodução', action: _player.stop);

  @override
  Future<void> dispose() =>
      _guard(operation: 'liberar player', action: _player.dispose);

  Future<void> _guard({
    required String operation,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } on PlatformException catch (error) {
      throw ContentAudioPlaybackException(operation: operation, cause: error);
    } on TimeoutException catch (error) {
      throw ContentAudioPlaybackException(operation: operation, cause: error);
    } on FlutterError catch (error) {
      throw ContentAudioPlaybackException(operation: operation, cause: error);
    } on Exception catch (error) {
      // O package usa Exception sem subtipo em falhas de preparação/início.
      throw ContentAudioPlaybackException(operation: operation, cause: error);
    }
  }
}
