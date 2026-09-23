import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CourseCatalogDocument', () {
    test('parses a valid data-driven course hierarchy', () {
      final document = CourseCatalogDocument.fromJson(_validCatalog());

      expect(document.schemaVersion, 2);
      expect(document.courses.single.id, 'course-1');
      expect(
        document
            .courses
            .single
            .modules
            .single
            .lessons
            .single
            .exercises
            .single
            .type,
        ExerciseType.key,
      );
      expect(
        document
            .courses
            .single
            .modules
            .single
            .lessons
            .single
            .exercises
            .single
            .expectedInput,
        'a',
      );
      expect(
        document
            .courses
            .single
            .modules
            .single
            .lessons
            .single
            .exercises
            .single
            .audio
            ?.assetPath,
        'assets/audio/demo/instruction_a_demo.wav',
      );
    });

    test('rejects duplicate exercise ids', () {
      final catalog = _validCatalog();
      final courses = catalog['courses']! as List<Object?>;
      final course = courses.single! as Map<String, Object?>;
      final modules = course['modules']! as List<Object?>;
      final module = modules.single! as Map<String, Object?>;
      final lessons = module['lessons']! as List<Object?>;
      final lesson = lessons.single! as Map<String, Object?>;
      final exercises = lesson['exercises']! as List<Object?>;
      exercises.add(
        Map<String, Object?>.from(exercises.single! as Map<String, Object?>),
      );

      expect(
        () => CourseCatalogDocument.fromJson(catalog),
        throwsA(isA<CourseContentFormatException>()),
      );
    });

    test('rejects unknown exercise types', () {
      final catalog = _validCatalog();
      final courses = catalog['courses']! as List<Object?>;
      final course = courses.single! as Map<String, Object?>;
      final modules = course['modules']! as List<Object?>;
      final module = modules.single! as Map<String, Object?>;
      final lessons = module['lessons']! as List<Object?>;
      final lesson = lessons.single! as Map<String, Object?>;
      final exercises = lesson['exercises']! as List<Object?>;
      final exercise = exercises.single! as Map<String, Object?>;
      exercise['type'] = 'telepathy';

      expect(
        () => CourseCatalogDocument.fromJson(catalog),
        throwsA(isA<CourseContentFormatException>()),
      );
    });

    test('rejects a key exercise without expected input', () {
      final catalog = _validCatalog();
      final courses = catalog['courses']! as List<Object?>;
      final course = courses.single! as Map<String, Object?>;
      final modules = course['modules']! as List<Object?>;
      final module = modules.single! as Map<String, Object?>;
      final lessons = module['lessons']! as List<Object?>;
      final lesson = lessons.single! as Map<String, Object?>;
      final exercises = lesson['exercises']! as List<Object?>;
      final exercise = exercises.single! as Map<String, Object?>;
      exercise.remove('expectedInput');

      expect(
        () => CourseCatalogDocument.fromJson(catalog),
        throwsA(isA<CourseContentFormatException>()),
      );
    });

    test('rejects an audio reference outside the audio asset directory', () {
      final catalog = _validCatalog();
      final exercise = _firstExercise(catalog);
      exercise['audio'] = <String, Object?>{
        'asset': '../private/instruction.wav',
      };

      expect(
        () => CourseCatalogDocument.fromJson(catalog),
        throwsA(isA<CourseContentFormatException>()),
      );
    });

    test('rejects an audio object without an asset path', () {
      final catalog = _validCatalog();
      final exercise = _firstExercise(catalog);
      exercise['audio'] = <String, Object?>{};

      expect(
        () => CourseCatalogDocument.fromJson(catalog),
        throwsA(isA<CourseContentFormatException>()),
      );
    });
  });
}

Map<String, Object?> _validCatalog() {
  return <String, Object?>{
    'schemaVersion': 2,
    'courses': <Object?>[
      <String, Object?>{
        'id': 'course-1',
        'title': 'Curso demo',
        'version': '0.1.0',
        'isDemo': true,
        'modules': <Object?>[
          <String, Object?>{
            'id': 'module-1',
            'title': 'Módulo demo',
            'lessons': <Object?>[
              <String, Object?>{
                'id': 'lesson-1',
                'title': 'Lição demo',
                'exercises': <Object?>[
                  <String, Object?>{
                    'id': 'exercise-1',
                    'title': 'Tecla F',
                    'type': 'key',
                    'prompt': 'Encontre a tecla F.',
                    'expectedInput': 'a',
                    'audio': <String, Object?>{
                      'asset': 'assets/audio/demo/instruction_a_demo.wav',
                    },
                  },
                ],
              },
            ],
          },
        ],
      },
    ],
  };
}

Map<String, Object?> _firstExercise(Map<String, Object?> catalog) {
  final courses = catalog['courses']! as List<Object?>;
  final course = courses.single! as Map<String, Object?>;
  final modules = course['modules']! as List<Object?>;
  final module = modules.single! as Map<String, Object?>;
  final lessons = module['lessons']! as List<Object?>;
  final lesson = lessons.single! as Map<String, Object?>;
  final exercises = lesson['exercises']! as List<Object?>;
  return exercises.single! as Map<String, Object?>;
}
