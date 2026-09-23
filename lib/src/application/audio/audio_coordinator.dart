import '../../domain/content/course_catalog.dart';
import 'content_audio_service.dart';

final class AudioCoordinator {
  factory AudioCoordinator({
    required ContentAudioService contentAudioService,
  }) => AudioCoordinator._(contentAudioService);

  AudioCoordinator._(this._contentAudioService);

  final ContentAudioService _contentAudioService;

  int _requestGeneration = 0;
  bool _isDisposed = false;
  Future<void> _operationTail = Future<void>.value();
  ContentAudioPlaybackException? _lastFailure;

  ContentAudioPlaybackException? get lastFailure => _lastFailure;

  Future<void> playContent(ContentAudioReference audio) {
    if (_isDisposed) {
      return Future<void>.value();
    }

    final generation = ++_requestGeneration;
    return _enqueue(() async {
      try {
        await _contentAudioService.stop();
        if (_isDisposed || generation != _requestGeneration) {
          return;
        }

        await _contentAudioService.playAsset(audio.assetPath);
        if (generation == _requestGeneration) {
          _lastFailure = null;
        }
      } on ContentAudioPlaybackException catch (error) {
        if (generation == _requestGeneration) {
          _lastFailure = error;
        }
      }
    });
  }

  Future<void> stop() {
    if (_isDisposed) {
      return Future<void>.value();
    }

    ++_requestGeneration;
    return _enqueue(() async {
      try {
        await _contentAudioService.stop();
      } on ContentAudioPlaybackException catch (error) {
        _lastFailure = error;
      }
    });
  }

  Future<void> dispose() {
    if (_isDisposed) {
      return Future<void>.value();
    }

    _isDisposed = true;
    ++_requestGeneration;
    return _enqueue(() async {
      try {
        await _contentAudioService.stop();
      } on ContentAudioPlaybackException catch (error) {
        _lastFailure = error;
      }

      try {
        await _contentAudioService.dispose();
      } on ContentAudioPlaybackException catch (error) {
        _lastFailure = error;
      }
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final scheduled = _operationTail.then((_) => operation());
    _operationTail = scheduled;
    return scheduled;
  }
}
