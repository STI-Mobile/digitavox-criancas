import 'dart:convert';
import 'dart:io';

import 'package:digitavox_criancas/src/application/exercise_sound_feedback.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';

Map<String, Object?> journeyJson() =>
    jsonDecode(File('docs/examples/journey_course.json').readAsStringSync())
        as Map<String, Object?>;

final class JourneyFixtureCatalog implements CourseCatalog {
  JourneyFixtureCatalog([Map<String, Object?>? json])
    : document = CourseCatalogDocument.fromJson(json ?? journeyJson());

  final CourseCatalogDocument document;

  @override
  Future<List<Course>> loadCourses() async => document.courses;
}

final class SilentExerciseFeedback implements ExerciseSoundFeedback {
  @override
  Future<void> playCorrect() async {}

  @override
  Future<void> playIncorrect() async {}
}
