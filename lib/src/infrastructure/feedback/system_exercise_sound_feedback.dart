import 'package:flutter/services.dart';

import '../../application/exercise_sound_feedback.dart';

final class SystemExerciseSoundFeedback implements ExerciseSoundFeedback {
  const SystemExerciseSoundFeedback();

  static const _errorPulseInterval = Duration(milliseconds: 120);

  @override
  Future<void> playCorrect() => _playClick();

  @override
  Future<void> playIncorrect() async {
    await _playClick();
    await Future<void>.delayed(_errorPulseInterval);
    await _playClick();
  }

  Future<void> _playClick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } on MissingPluginException {
      // A ausência do som da plataforma não deve interromper o exercício.
    } on PlatformException {
      // O feedback visual e semântico permanece disponível como alternativa.
    }
  }
}
