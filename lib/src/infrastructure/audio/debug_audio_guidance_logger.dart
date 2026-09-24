import 'package:flutter/foundation.dart';

import '../../application/audio/audio_guidance_services.dart';

final class DebugAudioGuidanceLogger implements AudioGuidanceLogger {
  const DebugAudioGuidanceLogger();

  @override
  void log(String event) => debugPrint(event);
}
