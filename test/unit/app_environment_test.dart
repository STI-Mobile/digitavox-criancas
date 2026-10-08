import 'package:digitavox_criancas/main.dart' as bootstrap;
import 'package:digitavox_criancas/src/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug exposes the technical fixture regardless of APP_ENV', () {
    final environment = AppEnvironment.fromBuild(
      isDebugBuild: true,
      configuredValue: 'beta',
    );

    expect(environment, AppEnvironment.debug);
    expect(environment.exposesTechnicalDemo, isTrue);
    expect(
      bootstrap.createCourseCatalogForEnvironment(environment).enabled,
      isTrue,
    );
  });

  test('beta exposes the technical fixture in a distributable build', () {
    final environment = AppEnvironment.fromBuild(
      isDebugBuild: false,
      configuredValue: 'beta',
    );

    expect(environment, AppEnvironment.beta);
    expect(environment.exposesTechnicalDemo, isTrue);
    expect(
      bootstrap.createCourseCatalogForEnvironment(environment).enabled,
      isTrue,
    );
  });

  test('release excludes the technical fixture by default', () {
    final environment = AppEnvironment.fromBuild(
      isDebugBuild: false,
      configuredValue: '',
    );

    expect(environment, AppEnvironment.release);
    expect(environment.exposesTechnicalDemo, isFalse);
    expect(
      bootstrap.createCourseCatalogForEnvironment(environment).enabled,
      isFalse,
    );
  });

  test('rejects unsupported release environment values', () {
    expect(
      () => AppEnvironment.fromBuild(
        isDebugBuild: false,
        configuredValue: 'staging',
      ),
      throwsArgumentError,
    );
  });
}
