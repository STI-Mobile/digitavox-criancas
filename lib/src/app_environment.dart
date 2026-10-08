/// Selects the behavior intended for a generated application build.
enum AppEnvironment {
  debug,
  beta,
  release;

  static AppEnvironment fromBuild({
    required bool isDebugBuild,
    required String configuredValue,
  }) {
    if (isDebugBuild) return debug;

    return switch (configuredValue) {
      '' => release,
      'beta' => beta,
      _ => throw ArgumentError.value(
        configuredValue,
        'configuredValue',
        'Use "beta" or omit APP_ENV for a production release.',
      ),
    };
  }

  bool get exposesTechnicalDemo => switch (this) {
    AppEnvironment.debug || AppEnvironment.beta => true,
    AppEnvironment.release => false,
  };
}
