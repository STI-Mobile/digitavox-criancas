import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:digitavox_criancas/src/infrastructure/content/development_course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exclui o catálogo técnico quando o modo de desenvolvimento está desabilitado', () async {
    final source = _CountingCourseCatalog();
    final catalog = DevelopmentCourseCatalog(
      demoCatalog: source,
      enabled: false,
    );

    expect(await catalog.loadCourses(), isEmpty);
    expect(source.loadCount, 0);
  });

  test(
    'usa o parser normal quando o modo de desenvolvimento está habilitado',
    () async {
      final source = _CountingCourseCatalog();
      final catalog = DevelopmentCourseCatalog(
        demoCatalog: source,
        enabled: true,
      );

      expect(await catalog.loadCourses(), same(source.courses));
      expect(source.loadCount, 1);
    },
  );
}

final class _CountingCourseCatalog implements CourseCatalog {
  final List<Course> courses = const <Course>[];
  var loadCount = 0;

  @override
  Future<List<Course>> loadCourses() async {
    loadCount++;
    return courses;
  }
}
