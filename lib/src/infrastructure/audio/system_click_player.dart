import 'package:flutter/services.dart';

import '../../application/audio/audio_guidance_services.dart';

/// Preserves the original soft one-click/two-click exercise feedback.
final class SystemClickPlayer {
  static const _pulseInterval = Duration(milliseconds: 120);
  var _generation = 0;

  Future<void> play({bool doubleClick = false}) async {
    final generation = ++_generation;
    await _playClick();
    if (!doubleClick) return;
    await Future<void>.delayed(_pulseInterval);
    if (generation != _generation) return;
    await _playClick();
  }

  /// A dispatched system click cannot be stopped, but a pending second pulse can.
  void stop() => ++_generation;

  Future<void> _playClick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } on MissingPluginException catch (error) {
      throw AudioServiceException(operation: 'playClick', cause: error);
    } on PlatformException catch (error) {
      throw AudioServiceException(operation: 'playClick', cause: error);
    }
  }
}
