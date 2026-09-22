abstract interface class ExerciseSoundFeedback {
  Future<void> playCorrect();

  Future<void> playIncorrect();
}
