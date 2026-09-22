enum ExerciseType {
  key,
  keySequence,
  word,
  phrase,
  timed,
  repetition,
  challenge;

  static ExerciseType parse(String value) {
    return ExerciseType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw CourseContentFormatException(
        'Tipo de exercício desconhecido: $value.',
      ),
    );
  }
}

final class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.type,
    required this.prompt,
    this.minimumRepetitions,
    this.timeLimitSeconds,
  });

  factory Exercise.fromJson(Map<String, Object?> json) {
    final minimumRepetitions = json['minimumRepetitions'];
    final timeLimitSeconds = json['timeLimitSeconds'];

    if (minimumRepetitions != null &&
        (minimumRepetitions is! int || minimumRepetitions < 1)) {
      throw const CourseContentFormatException(
        'minimumRepetitions deve ser um inteiro positivo.',
      );
    }
    if (timeLimitSeconds != null &&
        (timeLimitSeconds is! int || timeLimitSeconds < 1)) {
      throw const CourseContentFormatException(
        'timeLimitSeconds deve ser um inteiro positivo.',
      );
    }

    return Exercise(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      type: ExerciseType.parse(_requiredString(json, 'type')),
      prompt: _requiredString(json, 'prompt'),
      minimumRepetitions: minimumRepetitions as int?,
      timeLimitSeconds: timeLimitSeconds as int?,
    );
  }

  final String id;
  final String title;
  final ExerciseType type;
  final String prompt;
  final int? minimumRepetitions;
  final int? timeLimitSeconds;
}

final class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.exercises,
  });

  factory Lesson.fromJson(Map<String, Object?> json) {
    final exercises = _requiredObjectList(
      json,
      'exercises',
    ).map(Exercise.fromJson).toList(growable: false);
    _requireNonEmpty(exercises, 'Uma lição precisa ter exercícios.');
    _requireUniqueIds(exercises.map((exercise) => exercise.id), 'exercício');

    return Lesson(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      exercises: exercises,
    );
  }

  final String id;
  final String title;
  final List<Exercise> exercises;
}

final class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.lessons,
  });

  factory CourseModule.fromJson(Map<String, Object?> json) {
    final lessons = _requiredObjectList(
      json,
      'lessons',
    ).map(Lesson.fromJson).toList(growable: false);
    _requireNonEmpty(lessons, 'Um módulo precisa ter lições.');
    _requireUniqueIds(lessons.map((lesson) => lesson.id), 'lição');

    return CourseModule(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      lessons: lessons,
    );
  }

  final String id;
  final String title;
  final List<Lesson> lessons;
}

final class Course {
  const Course({
    required this.id,
    required this.title,
    required this.version,
    required this.isDemo,
    required this.modules,
  });

  factory Course.fromJson(Map<String, Object?> json) {
    final modules = _requiredObjectList(
      json,
      'modules',
    ).map(CourseModule.fromJson).toList(growable: false);
    _requireNonEmpty(modules, 'Um curso precisa ter módulos.');
    _requireUniqueIds(modules.map((module) => module.id), 'módulo');

    final isDemo = json['isDemo'];
    if (isDemo is! bool) {
      throw const CourseContentFormatException(
        'O campo isDemo deve ser booleano.',
      );
    }

    return Course(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      version: _requiredString(json, 'version'),
      isDemo: isDemo,
      modules: modules,
    );
  }

  final String id;
  final String title;
  final String version;
  final bool isDemo;
  final List<CourseModule> modules;
}

final class CourseCatalogDocument {
  const CourseCatalogDocument({
    required this.schemaVersion,
    required this.courses,
  });

  factory CourseCatalogDocument.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 1) {
      throw CourseContentFormatException(
        'Versão de schema não suportada: $schemaVersion.',
      );
    }

    final courses = _requiredObjectList(
      json,
      'courses',
    ).map(Course.fromJson).toList(growable: false);
    _requireNonEmpty(courses, 'O catálogo precisa ter ao menos um curso.');
    _requireUniqueIds(courses.map((course) => course.id), 'curso');

    return CourseCatalogDocument(
      schemaVersion: schemaVersion as int,
      courses: courses,
    );
  }

  final int schemaVersion;
  final List<Course> courses;
}

abstract interface class CourseCatalog {
  Future<List<Course>> loadCourses();
}

final class CourseContentFormatException implements Exception {
  const CourseContentFormatException(this.message);

  final String message;

  @override
  String toString() => 'CourseContentFormatException: $message';
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw CourseContentFormatException(
      'O campo obrigatório "$key" deve ser um texto não vazio.',
    );
  }
  return value;
}

List<Map<String, Object?>> _requiredObjectList(
  Map<String, Object?> json,
  String key,
) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw CourseContentFormatException(
      'O campo obrigatório "$key" deve ser uma lista.',
    );
  }

  return value
      .map((item) {
        if (item is! Map<String, Object?>) {
          throw CourseContentFormatException(
            'Todos os itens de "$key" devem ser objetos.',
          );
        }
        return item;
      })
      .toList(growable: false);
}

void _requireNonEmpty(List<Object?> values, String message) {
  if (values.isEmpty) {
    throw CourseContentFormatException(message);
  }
}

void _requireUniqueIds(Iterable<String> ids, String entityName) {
  final uniqueIds = <String>{};
  for (final id in ids) {
    if (!uniqueIds.add(id)) {
      throw CourseContentFormatException('ID de $entityName duplicado: $id.');
    }
  }
}
