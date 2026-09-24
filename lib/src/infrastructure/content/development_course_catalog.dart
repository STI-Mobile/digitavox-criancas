import '../../domain/content/course_catalog.dart';

/// Makes technical fixtures explicit and excludes them from release catalogs.
final class DevelopmentCourseCatalog implements CourseCatalog {
  const DevelopmentCourseCatalog({
    required this.demoCatalog,
    required this.enabled,
  });

  final CourseCatalog demoCatalog;
  final bool enabled;

  @override
  Future<List<Course>> loadCourses() =>
      enabled ? demoCatalog.loadCourses() : Future.value(const <Course>[]);
}
