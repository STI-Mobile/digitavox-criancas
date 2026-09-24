import 'package:flutter/services.dart';

import '../../application/audio/audio_guidance_services.dart';

final class PlatformTextToSpeechService implements TextToSpeechService {
  PlatformTextToSpeechService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'br.org.digitavox/audio_guidance_tts';
  final MethodChannel _channel;
  var _disposed = false;

  @override
  Future<void> initialize(SpeechConfiguration configuration) =>
      _invoke('initialize', <String, Object?>{
        'locale': configuration.locale,
        'rate': configuration.rate,
        'pitch': configuration.pitch,
        'volume': configuration.volume,
        'voice': configuration.voice,
      });

  @override
  Future<void> speak(String text) =>
      _invoke('speak', <String, Object?>{'text': text});

  @override
  Future<void> stop() => _disposed ? Future<void>.value() : _invoke('stop');

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    try {
      await _invoke('dispose');
    } finally {
      _disposed = true;
    }
  }

  Future<void> _invoke(String method, [Map<String, Object?>? arguments]) async {
    if (_disposed) {
      throw AudioServiceException(operation: method, cause: 'TTS descartado');
    }
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (error) {
      throw AudioServiceException(operation: method, cause: error);
    } on MissingPluginException catch (error) {
      throw AudioServiceException(operation: method, cause: error);
    }
  }
}
