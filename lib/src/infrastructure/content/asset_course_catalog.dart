import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/content/course_catalog.dart';

final class AssetCourseCatalog implements CourseCatalog {
  const AssetCourseCatalog({required this.assetPath, this.bundle});

  final String assetPath;
  final AssetBundle? bundle;

  @override
  Future<List<Course>> loadCourses() async {
    final source = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const CourseContentFormatException(
        'A raiz do catálogo deve ser um objeto JSON.',
      );
    }

    return CourseCatalogDocument.fromJson(decoded).courses;
  }
}
