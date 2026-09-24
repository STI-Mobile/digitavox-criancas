import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/journey_fixture.dart';

void main() {
  test('parses the documented scenes and characters at every level', () {
    final course = CourseCatalogDocument.fromJson(journeyJson()).courses.single;
    expect(course.scene!.characterId, 'aurora');
    expect(course.characters.length, 2);
    expect(
      course.modules.first.scene!.audioGuidance!.start.single.asset,
      'assets/audio/demo/preparation.wav',
    );
    final lesson = course.modules.first.lessons.first;
    expect(lesson.scene!.text, 'Encontre as marcas das teclas F e J.');
    expect(lesson.exercises.last.scene!.characterId, 'explorer');
  });

  test('rejects dangling character references at any hierarchy level', () {
    for (var level = 0; level < 4; level++) {
      final json = journeyJson();
      final course = (json['courses'] as List).single as Map<String, Object?>;
      final module = (course['modules'] as List).first as Map<String, Object?>;
      final lesson = (module['lessons'] as List).first as Map<String, Object?>;
      final exercise =
          (lesson['exercises'] as List).first as Map<String, Object?>;
      [course, module, lesson, exercise][level]['scene'] = {
        'text': 'Teste',
        'characterId': 'unknown',
      };
      expect(
        () => CourseCatalogDocument.fromJson(json),
        throwsA(isA<CourseContentFormatException>()),
      );
    }
  });

  test('rejects duplicate characters and unsafe image paths', () {
    final json = journeyJson();
    final course = (json['courses'] as List).single as Map<String, Object?>;
    final characters = course['characters'] as List;
    characters.add(Map<String, Object?>.from(characters.first as Map));
    expect(
      () => CourseCatalogDocument.fromJson(json),
      throwsA(isA<CourseContentFormatException>()),
    );
    characters.removeLast();
    for (final path in [
      'https://example.org/image.png',
      '../secret',
      'assets/images/../secret',
      'assets/images/',
      'assets/images/\\secret',
    ]) {
      (characters.first as Map)['imageAsset'] = path;
      expect(
        () => CourseCatalogDocument.fromJson(json),
        throwsA(isA<CourseContentFormatException>()),
      );
    }
  });

  test('requires accessible image descriptions and scene text, rejecting malformed types', () {
    for (final scene in [
      null,
      'text',
      <String, Object?>{},
      {'text': ''},
      {'text': 'Hi', 'audioGuidance': 'bad'},
      {'text': 'Hi', 'characterId': 42},
    ]) {
      final json = journeyJson();
      final course = (json['courses'] as List).single as Map<String, Object?>;
      course['scene'] = scene;
      expect(
        () => CourseCatalogDocument.fromJson(json),
        throwsA(isA<CourseContentFormatException>()),
      );
    }
    final json = journeyJson();
    final course = (json['courses'] as List).single as Map<String, Object?>;
    ((course['characters'] as List).first as Map).remove('imageDescription');
    expect(
      () => CourseCatalogDocument.fromJson(json),
      throwsA(isA<CourseContentFormatException>()),
    );
  });
}
