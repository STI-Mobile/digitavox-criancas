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

final class ContentAudioReference {
  const ContentAudioReference({required this.assetPath});

  factory ContentAudioReference.fromJson(Map<String, Object?> json) {
    final assetPath = _requiredString(json, 'asset');
    if (!assetPath.startsWith('assets/audio/') ||
        assetPath.contains('..') ||
        assetPath.endsWith('/')) {
      throw const CourseContentFormatException(
        'O asset de áudio deve apontar para um arquivo em assets/audio/.',
      );
    }

    return ContentAudioReference(assetPath: assetPath);
  }

  final String assetPath;
}

/// Optional narrative attached to a node of the course hierarchy.
final class ContentScene {
  const ContentScene({required this.text, this.audio, this.characterId});

  factory ContentScene.fromJson(Map<String, Object?> json) {
    final audio = _optionalObject(json, 'audio');
    return ContentScene(
      text: _requiredString(json, 'text'),
      audio: audio == null ? null : ContentAudioReference.fromJson(audio),
      characterId: json.containsKey('characterId')
          ? _requiredString(json, 'characterId')
          : null,
    );
  }

  final String text;
  final ContentAudioReference? audio;
  final String? characterId;
}

final class CourseCharacter {
  const CourseCharacter({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.imageDescription,
  });

  factory CourseCharacter.fromJson(Map<String, Object?> json) {
    final asset = _requiredString(json, 'imageAsset');
    if (!asset.startsWith('assets/images/') ||
        asset.contains('..') ||
        asset.contains('\\') ||
        asset.endsWith('/')) {
      throw const CourseContentFormatException(
        'A imagem do personagem deve apontar para um arquivo em assets/images/.',
      );
    }
    return CourseCharacter(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      imageAsset: asset,
      imageDescription: _requiredString(json, 'imageDescription'),
    );
  }

  final String id;
  final String name;
  final String imageAsset;
  final String imageDescription;
}

final class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.type,
    required this.prompt,
    this.expectedInput,
    this.minimumRepetitions,
    this.timeLimitSeconds,
    this.audio,
    this.scene,
  }) : assert(type != ExerciseType.key || expectedInput != null);

  factory Exercise.fromJson(Map<String, Object?> json) {
    final type = ExerciseType.parse(_requiredString(json, 'type'));
    final minimumRepetitions = json['minimumRepetitions'];
    final timeLimitSeconds = json['timeLimitSeconds'];
    final expectedInput = json['expectedInput'];
    final audio = json['audio'];

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
    if (expectedInput != null && expectedInput is! String) {
      throw const CourseContentFormatException(
        'expectedInput deve ser um texto.',
      );
    }
    if (type == ExerciseType.key &&
        (expectedInput is! String ||
            !_isSinglePrintableCharacter(expectedInput))) {
      throw const CourseContentFormatException(
        'Exercícios de tecla exigem expectedInput com exatamente uma tecla.',
      );
    }
    if (audio != null && audio is! Map<String, Object?>) {
      throw const CourseContentFormatException(
        'O campo audio deve ser um objeto.',
      );
    }

    return Exercise(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      type: type,
      prompt: _requiredString(json, 'prompt'),
      expectedInput: expectedInput as String?,
      minimumRepetitions: minimumRepetitions as int?,
      timeLimitSeconds: timeLimitSeconds as int?,
      audio: audio == null
          ? null
          : ContentAudioReference.fromJson(audio as Map<String, Object?>),
      scene: _scene(json),
    );
  }

  final String id;
  final String title;
  final ExerciseType type;
  final String prompt;
  final String? expectedInput;
  final int? minimumRepetitions;
  final int? timeLimitSeconds;
  final ContentAudioReference? audio;
  final ContentScene? scene;
}

final class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.exercises,
    this.scene,
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
      scene: _scene(json),
    );
  }

  final String id;
  final String title;
  final List<Exercise> exercises;
  final ContentScene? scene;
}

final class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.lessons,
    this.scene,
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
      scene: _scene(json),
    );
  }

  final String id;
  final String title;
  final List<Lesson> lessons;
  final ContentScene? scene;
}

final class Course {
  const Course({
    required this.id,
    required this.title,
    required this.version,
    required this.isDemo,
    required this.modules,
    this.scene,
    this.characters = const [],
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

    final characters = json.containsKey('characters')
        ? _requiredObjectList(
            json,
            'characters',
          ).map(CourseCharacter.fromJson).toList(growable: false)
        : <CourseCharacter>[];
    _requireUniqueIds(
      characters.map((character) => character.id),
      'personagem',
    );
    final scene = _scene(json);
    final characterIds = characters.map((character) => character.id).toSet();
    final scenes = <ContentScene?>[
      scene,
      for (final module in modules) ...[
        module.scene,
        for (final lesson in module.lessons) ...[
          lesson.scene,
          for (final exercise in lesson.exercises) exercise.scene,
        ],
      ],
    ];
    for (final scene in scenes) {
      final id = scene?.characterId;
      if (id != null && !characterIds.contains(id)) {
        throw CourseContentFormatException('Personagem desconhecido: $id.');
      }
    }

    return Course(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      version: _requiredString(json, 'version'),
      isDemo: isDemo,
      modules: modules,
      scene: scene,
      characters: characters,
    );
  }

  final String id;
  final String title;
  final String version;
  final bool isDemo;
  final List<CourseModule> modules;
  final ContentScene? scene;
  final List<CourseCharacter> characters;
}

final class CourseCatalogDocument {
  const CourseCatalogDocument({
    required this.schemaVersion,
    required this.courses,
  });

  factory CourseCatalogDocument.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 2) {
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

Map<String, Object?>? _optionalObject(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) return null;
  final value = json[key];
  if (value is! Map<String, Object?>) {
    throw CourseContentFormatException('O campo $key deve ser um objeto.');
  }
  return value;
}

ContentScene? _scene(Map<String, Object?> json) {
  final scene = _optionalObject(json, 'scene');
  return scene == null ? null : ContentScene.fromJson(scene);
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

bool _isSinglePrintableCharacter(String value) {
  if (value.runes.length != 1) {
    return false;
  }
  final codePoint = value.runes.single;
  return codePoint >= 0x20 && codePoint != 0x7f;
}
