import 'dart:convert';

import '../../domain/progress/student_progress.dart';

class ProgressDataFormatException implements Exception {
  const ProgressDataFormatException(this.message);

  final String message;

  @override
  String toString() => 'ProgressDataFormatException: $message';
}

final class UnsupportedProgressSchemaException
    extends ProgressDataFormatException {
  const UnsupportedProgressSchemaException(int version)
    : super('Versão de schema não suportada: $version.');
}

final class StudentProgressCodec {
  const StudentProgressCodec();

  static const int schemaVersion = 2;
  static const String _coursesPath = r'$.progress.courses';

  String encode(StudentProgress progress) {
    final courses = <String, Object?>{};
    final courseIds = progress.courses.keys.toList()..sort();

    for (final courseId in courseIds) {
      _validateId(courseId, _coursesPath);
      final course = progress.courses[courseId]!;
      final coursePath = '$_coursesPath.$courseId';
      final lessons = <String, Object?>{};
      final lessonIds = course.lessons.keys.toList()..sort();

      for (final lessonId in lessonIds) {
        _validateId(lessonId, '$coursePath.lessons');
        final lesson = course.lessons[lessonId]!;
        if (lesson.stars < 0) {
          throw ProgressDataFormatException(
            'Estrelas não podem ser negativas na lição "$lessonId".',
          );
        }

        final completedExerciseIds = lesson.completedExerciseIds.toList()
          ..sort();
        for (final exerciseId in completedExerciseIds) {
          _validateId(
            exerciseId,
            '$coursePath.lessons.$lessonId.completedExerciseIds',
          );
        }

        lessons[lessonId] = <String, Object?>{
          'completedExerciseIds': completedExerciseIds,
          'stars': lesson.stars,
        };
      }

      courses[courseId] = <String, Object?>{'lessons': lessons};
    }

    return jsonEncode(<String, Object?>{
      'schemaVersion': schemaVersion,
      'progress': <String, Object?>{
        'courses': courses,
        'settings': <String, Object?>{
          'spokenFeedbackEnabled': progress.settings.spokenFeedbackEnabled,
          'themePreference': progress.settings.themePreference.name,
        },
      },
    });
  }

  StudentProgress decode(String document) {
    final Object? decoded;
    try {
      decoded = jsonDecode(document);
    } on FormatException catch (error) {
      throw ProgressDataFormatException('JSON inválido: ${error.message}');
    }

    final root = _expectObject(decoded, r'$');
    final version = _expectInt(root['schemaVersion'], r'$.schemaVersion');
    if (version != 1 && version != schemaVersion) {
      throw UnsupportedProgressSchemaException(version);
    }

    final progress = _expectObject(root['progress'], r'$.progress');
    final coursesJson = _expectObject(progress['courses'], _coursesPath);
    final settingsJson = _expectObject(
      progress['settings'],
      r'$.progress.settings',
    );
    final courses = <String, CourseProgress>{};

    for (final MapEntry(key: courseId, value: courseValue)
        in coursesJson.entries) {
      _validateId(courseId, _coursesPath);
      final coursePath = '$_coursesPath.$courseId';
      final courseJson = _expectObject(courseValue, coursePath);
      final lessonsJson = _expectObject(
        courseJson['lessons'],
        '$coursePath.lessons',
      );
      final lessons = <String, LessonProgress>{};

      for (final MapEntry(key: lessonId, value: lessonValue)
          in lessonsJson.entries) {
        _validateId(lessonId, '$coursePath.lessons');
        final lessonPath = '$coursePath.lessons.$lessonId';
        final lessonJson = _expectObject(lessonValue, lessonPath);
        final completedJson = _expectList(
          lessonJson['completedExerciseIds'],
          '$lessonPath.completedExerciseIds',
        );
        final completedExerciseIds = <String>{};

        for (var index = 0; index < completedJson.length; index++) {
          final exerciseId = _expectString(
            completedJson[index],
            '$lessonPath.completedExerciseIds[$index]',
          );
          _validateId(exerciseId, '$lessonPath.completedExerciseIds[$index]');
          if (!completedExerciseIds.add(exerciseId)) {
            throw ProgressDataFormatException(
              'Exercício duplicado em $lessonPath.completedExerciseIds: '
              '"$exerciseId".',
            );
          }
        }

        final stars = _expectInt(lessonJson['stars'], '$lessonPath.stars');
        if (stars < 0) {
          throw ProgressDataFormatException(
            'Valor negativo em $lessonPath.stars.',
          );
        }

        lessons[lessonId] = LessonProgress(
          completedExerciseIds: Set.unmodifiable(completedExerciseIds),
          stars: stars,
        );
      }

      courses[courseId] = CourseProgress(lessons: Map.unmodifiable(lessons));
    }

    return StudentProgress(
      courses: Map.unmodifiable(courses),
      settings: AppSettings(
        spokenFeedbackEnabled: _expectBool(
          settingsJson['spokenFeedbackEnabled'],
          r'$.progress.settings.spokenFeedbackEnabled',
        ),
        themePreference: version == 1
            ? (_expectBool(
                    settingsJson['highContrastEnabled'],
                    r'$.progress.settings.highContrastEnabled',
                  )
                  ? AppThemePreference.highContrast
                  : AppThemePreference.standard)
            : _themePreference(settingsJson['themePreference']),
      ),
    );
  }

  static Map<String, Object?> _expectObject(Object? value, String path) {
    if (value is! Map<String, Object?>) {
      throw ProgressDataFormatException('Objeto obrigatório em $path.');
    }
    return value;
  }

  static List<Object?> _expectList(Object? value, String path) {
    if (value is! List<Object?>) {
      throw ProgressDataFormatException('Lista obrigatória em $path.');
    }
    return value;
  }

  static int _expectInt(Object? value, String path) {
    if (value is! int) {
      throw ProgressDataFormatException('Inteiro obrigatório em $path.');
    }
    return value;
  }

  static String _expectString(Object? value, String path) {
    if (value is! String) {
      throw ProgressDataFormatException('Texto obrigatório em $path.');
    }
    return value;
  }

  static bool _expectBool(Object? value, String path) {
    if (value is! bool) {
      throw ProgressDataFormatException('Booleano obrigatório em $path.');
    }
    return value;
  }

  static AppThemePreference _themePreference(Object? value) {
    final name = _expectString(value, r'$.progress.settings.themePreference');
    try {
      return AppThemePreference.parse(name);
    } on ArgumentError {
      throw ProgressDataFormatException(
        'Tema desconhecido em \$.progress.settings.themePreference: "$name".',
      );
    }
  }

  static void _validateId(String id, String path) {
    if (id.trim().isEmpty) {
      throw ProgressDataFormatException('Identificador vazio em $path.');
    }
  }
}
