/// Selects the behavior intended for a generated application build.
///
/// Distributable builds are identified by their flavor. See
/// docs/adr/0005-apps-separados-dev-prod.md.
enum AppEnvironment {
  debug,
  dev,
  prod;

  static AppEnvironment fromBuild({
    required bool isDebugBuild,
    required String? flavor,
  }) {
    if (isDebugBuild) return debug;

    return switch (flavor) {
      'dev' => dev,
      'prod' => prod,
      _ => throw ArgumentError.value(
        flavor,
        'flavor',
        'Build release versions with --flavor dev or --flavor prod.',
      ),
    };
  }

  bool get exposesTechnicalDemo => switch (this) {
    AppEnvironment.debug || AppEnvironment.dev => true,
    AppEnvironment.prod => false,
  };
}
