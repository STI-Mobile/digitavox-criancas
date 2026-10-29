import '../../domain/content/course_catalog.dart';

final class CombinedCourseCatalog implements CourseCatalog {
  const CombinedCourseCatalog({required this.catalogs});

  final List<CourseCatalog> catalogs;

  @override
  Future<List<Course>> loadCourses() async {
    final loadedCatalogs = await Future.wait(
      catalogs.map((catalog) => catalog.loadCourses()),
    );
    return List<Course>.unmodifiable([
      for (final courses in loadedCatalogs) ...courses,
    ]);
  }
}
