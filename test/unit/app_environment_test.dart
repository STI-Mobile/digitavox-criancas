import 'package:digitavox_criancas/main.dart' as bootstrap;
import 'package:digitavox_criancas/src/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug exposes the technical fixture regardless of flavor', () {
    final environment = AppEnvironment.fromBuild(
      isDebugBuild: true,
      flavor: 'prod',
    );

    expect(environment, AppEnvironment.debug);
    expect(environment.exposesTechnicalDemo, isTrue);
    expect(
      bootstrap.createCourseCatalogForEnvironment(environment).enabled,
      isTrue,
    );
  });

  test('dev exposes the technical fixture in a distributable build', () {
    final environment = AppEnvironment.fromBuild(
      isDebugBuild: false,
      flavor: 'dev',
    );

    expect(environment, AppEnvironment.dev);
    expect(environment.exposesTechnicalDemo, isTrue);
    expect(
      bootstrap.createCourseCatalogForEnvironment(environment).enabled,
      isTrue,
    );
  });

  test('prod excludes the technical fixture from release builds', () {
    final environment = AppEnvironment.fromBuild(
      isDebugBuild: false,
      flavor: 'prod',
    );

    expect(environment, AppEnvironment.prod);
    expect(environment.exposesTechnicalDemo, isFalse);
    expect(
      bootstrap.createCourseCatalogForEnvironment(environment).enabled,
      isFalse,
    );
  });

  test('rejects release builds without a known flavor', () {
    for (final flavor in [null, '', 'staging']) {
      expect(
        () => AppEnvironment.fromBuild(isDebugBuild: false, flavor: flavor),
        throwsArgumentError,
      );
    }
  });
}
