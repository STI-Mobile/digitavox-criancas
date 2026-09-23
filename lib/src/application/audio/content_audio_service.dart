abstract interface class ContentAudioService {
  Future<void> playAsset(String assetPath);

  Future<void> stop();

  Future<void> dispose();
}

final class ContentAudioPlaybackException implements Exception {
  const ContentAudioPlaybackException({
    required this.operation,
    required this.cause,
  });

  final String operation;
  final Object cause;

  @override
  String toString() =>
      'ContentAudioPlaybackException durante $operation: $cause';
}
