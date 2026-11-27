part 'course_configuration.dart';

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

enum CourseAudioEvent { start, correctInput, incorrectInput, completed }

enum ContentAudioCueType {
  speech,
  sfx,
  music;

  static ContentAudioCueType parse(String value) {
    return ContentAudioCueType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw CourseContentFormatException(
        'Tipo de cue de áudio desconhecido: $value.',
      ),
    );
  }
}

enum ContentAudioFallback { text, silent, systemClick }

/// Declarative audio intent. It contains no player or platform configuration.
final class ContentAudioCue {
  const ContentAudioCue({
    required this.id,
    required this.type,
    this.text,
    this.asset,
    this.speaker,
    this.pending = false,
    this.fallback,
  });

  factory ContentAudioCue.fromJson(Map<String, Object?> json) {
    const supportedKeys = <String>{
      'id',
      'type',
      'text',
      'asset',
      'speaker',
      'pending',
      'fallback',
    };
    final unknownKeys = json.keys.where((key) => !supportedKeys.contains(key));
    if (unknownKeys.isNotEmpty) {
      throw CourseContentFormatException(
        'Campo de cue de áudio desconhecido: ${unknownKeys.first}.',
      );
    }

    final type = ContentAudioCueType.parse(_requiredString(json, 'type'));
    final text = _optionalString(json, 'text');
    final asset = _optionalString(json, 'asset');
    final speaker = _optionalString(json, 'speaker');
    final pending = _optionalBool(json, 'pending', false);
    final fallback = json['fallback'] == null
        ? null
        : _enumValue(ContentAudioFallback.values, json['fallback'], 'fallback');
    if (pending && (asset != null || fallback == null)) {
      throw const CourseContentFormatException(
        'Áudio pendente exige fallback explícito e não declara asset pronto.',
      );
    }
    final validPendingFallback = switch (type) {
      ContentAudioCueType.speech => fallback == ContentAudioFallback.text,
      ContentAudioCueType.sfx =>
        fallback == ContentAudioFallback.silent ||
            fallback == ContentAudioFallback.systemClick,
      ContentAudioCueType.music => fallback == ContentAudioFallback.silent,
    };
    if (pending && !validPendingFallback) {
      throw const CourseContentFormatException(
        'Fallback pendente incompatível com o tipo de áudio.',
      );
    }
    if (fallback == ContentAudioFallback.systemClick &&
        (!pending || type != ContentAudioCueType.sfx)) {
      throw const CourseContentFormatException(
        'systemClick é permitido apenas para sfx pendente.',
      );
    }
    if (fallback == ContentAudioFallback.text &&
        (type != ContentAudioCueType.speech || text == null)) {
      throw const CourseContentFormatException(
        'Fallback text exige speech com texto.',
      );
    }

    if (asset != null) _validateAudioAsset(asset);
    switch (type) {
      case ContentAudioCueType.speech:
        if (text == null && asset == null) {
          throw const CourseContentFormatException(
            'Um cue speech precisa de text ou asset.',
          );
        }
      case ContentAudioCueType.sfx || ContentAudioCueType.music:
        if (asset == null && !pending) {
          throw CourseContentFormatException(
            'Um cue ${type.name} precisa de asset.',
          );
        }
        if (text != null || speaker != null) {
          throw CourseContentFormatException(
            'Um cue ${type.name} não aceita text ou speaker.',
          );
        }
    }

    return ContentAudioCue(
      id: _requiredString(json, 'id'),
      type: type,
      text: text,
      asset: asset,
      speaker: speaker,
      pending: pending,
      fallback: fallback,
    );
  }

  final String id;
  final ContentAudioCueType type;
  final String? text;
  final String? asset;
  final String? speaker;
  final bool pending;
  final ContentAudioFallback? fallback;
}

/// Ordered cues keyed by generic course lifecycle events.
final class CourseAudioConfiguration {
  const CourseAudioConfiguration({
    this.start = const <ContentAudioCue>[],
    this.correctInput = const <ContentAudioCue>[],
    this.incorrectInput = const <ContentAudioCue>[],
    this.completed = const <ContentAudioCue>[],
  });

  factory CourseAudioConfiguration.fromJson(Map<String, Object?> json) {
    final supportedKeys = CourseAudioEvent.values
        .map((event) => event.name)
        .toSet();
    final unknownKeys = json.keys.where((key) => !supportedKeys.contains(key));
    if (unknownKeys.isNotEmpty) {
      throw CourseContentFormatException(
        'Evento de áudio desconhecido: ${unknownKeys.first}.',
      );
    }

    return CourseAudioConfiguration(
      start: _audioCueList(json, CourseAudioEvent.start.name),
      correctInput: _audioCueList(json, CourseAudioEvent.correctInput.name),
      incorrectInput: _audioCueList(json, CourseAudioEvent.incorrectInput.name),
      completed: _audioCueList(json, CourseAudioEvent.completed.name),
    );
  }

  final List<ContentAudioCue> start;
  final List<ContentAudioCue> correctInput;
  final List<ContentAudioCue> incorrectInput;
  final List<ContentAudioCue> completed;

  List<ContentAudioCue> cuesFor(CourseAudioEvent event) => switch (event) {
    CourseAudioEvent.start => start,
    CourseAudioEvent.correctInput => correctInput,
    CourseAudioEvent.incorrectInput => incorrectInput,
    CourseAudioEvent.completed => completed,
  };

  /// A child overrides only its declared events, not the entire parent policy.
  CourseAudioConfiguration inheritFrom(CourseAudioConfiguration? parent) =>
      CourseAudioConfiguration(
        start: start.isNotEmpty ? start : parent?.start ?? const [],
        correctInput: correctInput.isNotEmpty
            ? correctInput
            : parent?.correctInput ?? const [],
        incorrectInput: incorrectInput.isNotEmpty
            ? incorrectInput
            : parent?.incorrectInput ?? const [],
        completed: completed.isNotEmpty
            ? completed
            : parent?.completed ?? const [],
      );
}

/// Ordered, character-associated content attached to a course node.
final class ContentScene {
  const ContentScene({
    required this.lines,
    this.audioGuidance,
    this.illustrationId,
  });

  factory ContentScene.fromJson(Map<String, Object?> json) {
    final lines = json.containsKey('lines')
        ? _optionalObjects(
            json,
            'lines',
          ).map(ContentSceneLine.fromJson).toList(growable: false)
        : _legacySceneLines(json);
    return ContentScene(
      lines: List.unmodifiable(lines),
      audioGuidance: _courseAudioConfiguration(json),
      illustrationId: _optionalString(json, 'illustrationId'),
    );
  }

  final List<ContentSceneLine> lines;
  final CourseAudioConfiguration? audioGuidance;
  final String? illustrationId;

  String get text => lines
      .map((line) => line.text)
      .where((text) => text.isNotEmpty)
      .join('\n\n');
}

final class ContentSceneLine {
  const ContentSceneLine({
    required this.characterId,
    required this.audioCues,
    this.fallbackText,
  });

  factory ContentSceneLine.fromJson(Map<String, Object?> json) =>
      ContentSceneLine(
        characterId: _requiredString(json, 'characterId'),
        audioCues: _optionalCueObjects(json, 'audioCues'),
      );

  final String? characterId;
  final List<ContentAudioCue> audioCues;
  final String? fallbackText;

  String get text {
    if (fallbackText != null) return fallbackText!;
    final speech = audioCues
        .where((cue) => cue.type == ContentAudioCueType.speech)
        .map((cue) => cue.text)
        .whereType<String>()
        .join('\n\n');
    return speech;
  }

  bool get hasSpeech =>
      audioCues.any((cue) => cue.type == ContentAudioCueType.speech);
}

final class ContentPostScene {
  const ContentPostScene({required this.illustrationId, this.lines = const []});

  factory ContentPostScene.fromJson(Map<String, Object?> json) =>
      ContentPostScene(
        illustrationId: _requiredString(json, 'illustrationId'),
        lines: List.unmodifiable(
          _optionalObjects(json, 'lines').map(ContentSceneLine.fromJson),
        ),
      );

  final String illustrationId;
  final List<ContentSceneLine> lines;
}

List<ContentSceneLine> _legacySceneLines(Map<String, Object?> json) {
  final characterId = json.containsKey('characterId')
      ? _requiredString(json, 'characterId')
      : null;
  final audioGuidance = _courseAudioConfiguration(json);
  final narrationCues = _optionalCueObjects(json, 'narrationCues');
  final instructionCues = _optionalCueObjects(json, 'instructionCues');
  final legacyText = _requiredString(json, 'text');
  final instruction = json['instruction'] as String? ?? '';
  return [
    ContentSceneLine(
      characterId:
          characterId ??
          narrationCues
              .map((cue) => cue.speaker)
              .whereType<String>()
              .firstOrNull,
      audioCues: narrationCues.isNotEmpty
          ? narrationCues
          : audioGuidance?.start ?? const [],
      fallbackText: legacyText,
    ),
    if (instruction.isNotEmpty)
      ContentSceneLine(
        characterId:
            characterId ??
            instructionCues
                .map((cue) => cue.speaker)
                .whereType<String>()
                .firstOrNull,
        audioCues: instructionCues,
        fallbackText: instruction,
      ),
  ];
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
    _validateImageAsset(asset);
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

void _validateImageAsset(String asset) {
  if (!asset.startsWith('assets/images/') ||
      asset.contains('..') ||
      asset.contains('\\') ||
      asset.endsWith('/')) {
    throw const CourseContentFormatException(
      'A imagem deve apontar para um arquivo em assets/images/.',
    );
  }
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
    this.audioGuidance,
    this.scene,
    this.spellOut = false,
    this.repetitionSeparator = '',
    this.trailingSeparator = '',
    this.timePerCharacterSeconds,
  }) : assert(type != ExerciseType.key || expectedInput != null);

  factory Exercise.fromJson(Map<String, Object?> json) {
    final type = ExerciseType.parse(_requiredString(json, 'type'));
    final minimumRepetitions = json['minimumRepetitions'];
    final timeLimitSeconds = json['timeLimitSeconds'];
    final expectedInput = json['expectedInput'];

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
    return Exercise(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      type: type,
      prompt: _requiredString(json, 'prompt'),
      expectedInput: expectedInput as String?,
      minimumRepetitions: minimumRepetitions as int?,
      timeLimitSeconds: timeLimitSeconds as int?,
      audioGuidance: _courseAudioConfiguration(json),
      scene: _scene(json),
      spellOut: _optionalBool(json, 'spellOut', false),
      repetitionSeparator: json['repetitionSeparator'] as String? ?? '',
      trailingSeparator: json['trailingSeparator'] as String? ?? '',
      timePerCharacterSeconds: json['timePerCharacterSeconds'] as int?,
    );
  }

  final String id;
  final String title;
  final ExerciseType type;
  final String prompt;
  final String? expectedInput;
  final int? minimumRepetitions;
  final int? timeLimitSeconds;
  final CourseAudioConfiguration? audioGuidance;
  final ContentScene? scene;
  final bool spellOut;
  final String repetitionSeparator;
  final String trailingSeparator;
  final int? timePerCharacterSeconds;

  String inputForRepetition(int repetition) {
    final count = minimumRepetitions ?? 1;
    if (repetition < 1 || repetition > count) {
      throw RangeError.range(repetition, 1, count, 'repetition');
    }
    return '${expectedInput ?? ''}${repetition < count ? repetitionSeparator : trailingSeparator}';
  }

  String get completeExpectedInput => [
    for (var i = 1; i <= (minimumRepetitions ?? 1); i++) inputForRepetition(i),
  ].join();

  int? effectiveTimeLimitSeconds({int? defaultSecondsPerCharacter}) {
    if (timeLimitSeconds != null) return timeLimitSeconds;
    final seconds = timePerCharacterSeconds ?? defaultSecondsPerCharacter;
    return seconds == null || seconds < 1
        ? null
        : (seconds *
                  (minimumRepetitions ?? 1) *
                  ((expectedInput?.runes.length ?? 0) + 1)) -
              1;
  }
}

final class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.exercises,
    this.accuracy = 90,
    this.secChar = 0,
    this.audioGuidance,
    this.leadingScene,
    this.postScene,
    this.prerequisiteLessonIds = const [],
    this.optional = false,
    this.prerequisiteEventId,
    this.legacyLessonIds = const [],
  });

  factory Lesson.fromJson(Map<String, Object?> json) {
    final exercises = _requiredObjectList(
      json,
      'exercises',
    ).map(Exercise.fromJson).toList(growable: false);
    _requireNonEmpty(exercises, 'Uma lição precisa ter exercícios.');
    _requireUniqueIds(exercises.map((exercise) => exercise.id), 'exercício');
    final accuracy = _optionalPercentage(json, 'accuracy', defaultValue: 90);
    final secChar = _optionalPositiveInteger(json, 'secChar', defaultValue: 0);

    return Lesson(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      exercises: exercises,
      audioGuidance: _courseAudioConfiguration(json),
      leadingScene: json.containsKey('leadingScene')
          ? ContentScene.fromJson(_optionalObject(json, 'leadingScene')!)
          : _scene(json),
      postScene: json.containsKey('postScene')
          ? ContentPostScene.fromJson(_optionalObject(json, 'postScene')!)
          : null,
      accuracy: accuracy,
      secChar: secChar,
      prerequisiteLessonIds: _optionalTextList(json, 'prerequisiteLessonIds'),
      optional: _optionalBool(json, 'optional', false),
      prerequisiteEventId: _optionalString(json, 'prerequisiteEventId'),
      legacyLessonIds: _optionalTextList(json, 'legacyLessonIds'),
    );
  }

  final String id;
  final String title;
  final List<Exercise> exercises;
  final CourseAudioConfiguration? audioGuidance;
  final ContentScene? leadingScene;
  final ContentPostScene? postScene;
  final int accuracy;
  final int secChar;
  final List<String> prerequisiteLessonIds;
  final bool optional;
  final String? prerequisiteEventId;
  final List<String> legacyLessonIds;
  ContentScene? get scene => leadingScene;
}

final class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.lessons,
    this.audioGuidance,
    this.leadingScene,
    this.postScene,
    this.allowedKeys = const [],
    this.vocabulary = const [],
    this.completionEvent,
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
      audioGuidance: _courseAudioConfiguration(json),
      leadingScene: json.containsKey('leadingScene')
          ? ContentScene.fromJson(_optionalObject(json, 'leadingScene')!)
          : _scene(json),
      postScene: json.containsKey('postScene')
          ? ContentPostScene.fromJson(_optionalObject(json, 'postScene')!)
          : null,
      allowedKeys: _optionalTextList(json, 'allowedKeys', allowSpace: true),
      vocabulary: _optionalTextList(json, 'vocabulary'),
      completionEvent: json['completionEvent'] == null
          ? null
          : ContentEvent.fromJson(_optionalObject(json, 'completionEvent')!),
    );
  }

  final String id;
  final String title;
  final List<Lesson> lessons;
  final CourseAudioConfiguration? audioGuidance;
  final ContentScene? leadingScene;
  final ContentPostScene? postScene;
  ContentScene? get scene => leadingScene;
  final List<String> allowedKeys;
  final List<String> vocabulary;
  final ContentEvent? completionEvent;
}

final class Course {
  const Course({
    required this.id,
    required this.title,
    required this.version,
    required this.isDemo,
    required this.modules,
    this.themeId = 'default',
    this.audioGuidance,
    this.scene,
    this.characters = const [],
    this.illustrations = const [],
    this.practice = const CoursePracticeConfiguration(),
    this.rewards = const CourseRewardConfiguration(),
    this.audioResources = const {},
    this.rewardDefinitions = const [],
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
        module.leadingScene,
        for (final lesson in module.lessons) ...[
          lesson.leadingScene,
          for (final exercise in lesson.exercises) exercise.scene,
        ],
      ],
    ];
    for (final scene in scenes) {
      for (final line in scene?.lines ?? const <ContentSceneLine>[]) {
        final id = line.characterId;
        if (id != null && !characterIds.contains(id)) {
          throw CourseContentFormatException('Personagem desconhecido: $id.');
        }
      }
    }
    for (final postScene in [
      for (final module in modules) module.postScene,
      for (final lesson in modules.expand((module) => module.lessons))
        lesson.postScene,
    ]) {
      for (final line in postScene?.lines ?? const <ContentSceneLine>[]) {
        final id = line.characterId;
        if (id != null && !characterIds.contains(id)) {
          throw CourseContentFormatException('Personagem desconhecido: $id.');
        }
      }
    }
    final illustrations = _optionalObjects(
      json,
      'illustrations',
    ).map(CourseIllustration.fromJson).toList(growable: false);
    _requireUniqueIds(
      illustrations.map((illustration) => illustration.id),
      'ilustração',
    );
    final illustrationIds = illustrations
        .map((illustration) => illustration.id)
        .toSet();
    for (final lesson in modules.expand((module) => module.lessons)) {
      final illustrationId = lesson.postScene?.illustrationId;
      if (illustrationId != null && !illustrationIds.contains(illustrationId)) {
        throw CourseContentFormatException(
          'Ilustração pós-missão desconhecida: $illustrationId.',
        );
      }
    }
    for (final module in modules) {
      final illustrationId = module.postScene?.illustrationId;
      if (illustrationId != null && !illustrationIds.contains(illustrationId)) {
        throw CourseContentFormatException(
          'Ilustração pós-cena desconhecida: $illustrationId.',
        );
      }
    }

    return Course(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      version: _requiredString(json, 'version'),
      isDemo: isDemo,
      modules: modules,
      themeId: json.containsKey('theme')
          ? _requiredString(json, 'theme')
          : 'default',
      audioGuidance: _courseAudioConfiguration(json),
      scene: scene,
      characters: characters,
      illustrations: illustrations,
      practice: CoursePracticeConfiguration.fromJson(
        _optionalObject(json, 'practice') ?? const {},
      ),
      rewards: CourseRewardConfiguration.fromJson(
        _optionalObject(json, 'rewards') ?? const {},
      ),
      audioResources: {
        for (final resource in _optionalObjects(json, 'audioResources'))
          _requiredString(resource, 'id'): ContentAudioCue.fromJson(resource),
      },
      rewardDefinitions: _optionalObjects(
        json,
        'rewardDefinitions',
      ).map(RewardDefinition.fromJson).toList(growable: false),
    );
  }

  final String id;
  final String title;
  final String version;
  final bool isDemo;
  final List<CourseModule> modules;
  final String themeId;
  final CourseAudioConfiguration? audioGuidance;
  final ContentScene? scene;
  final List<CourseCharacter> characters;
  final List<CourseIllustration> illustrations;
  final CoursePracticeConfiguration practice;
  final CourseRewardConfiguration rewards;
  final Map<String, ContentAudioCue> audioResources;
  final List<RewardDefinition> rewardDefinitions;
}

final class CourseCatalogDocument {
  const CourseCatalogDocument({
    required this.schemaVersion,
    required this.courses,
  });

  factory CourseCatalogDocument.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 2 &&
        schemaVersion != 3 &&
        schemaVersion != 4 &&
        schemaVersion != 5) {
      throw CourseContentFormatException(
        'Versão de schema não suportada: $schemaVersion.',
      );
    }

    if (schemaVersion == 4 || schemaVersion == 5) {
      _requireKeys(json, {'schemaVersion', 'courses'}, 'catálogo');
    }
    final courses = _requiredObjectList(json, 'courses')
        .map(
          (course) => Course.fromJson(switch (schemaVersion) {
            4 => _prepareSchema5Course(_upgradeSchema4Course(course)),
            5 => _prepareSchema5Course(course),
            _ => course,
          }),
        )
        .toList(growable: false);
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

int _optionalPercentage(
  Map<String, Object?> json,
  String key, {
  required int defaultValue,
}) {
  final value = json[key];
  if (value == null) return defaultValue;
  final percentage = value is int
      ? value
      : value is String
      ? int.tryParse(value)
      : null;
  if (percentage == null || percentage < 0 || percentage > 100) {
    throw CourseContentFormatException(
      'O campo "$key" deve ser um percentual inteiro entre 0 e 100.',
    );
  }
  return percentage;
}

int _optionalPositiveInteger(
  Map<String, Object?> json,
  String key, {
  required int defaultValue,
}) {
  final value = json[key];
  if (value == null) return defaultValue;
  final integer = value is int
      ? value
      : value is String
      ? int.tryParse(value)
      : null;
  if (integer == null || integer < 1) {
    throw CourseContentFormatException(
      'O campo "$key" deve ser um inteiro positivo.',
    );
  }
  return integer;
}

String? _optionalString(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) return null;
  return _requiredString(json, key);
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

CourseAudioConfiguration? _courseAudioConfiguration(Map<String, Object?> json) {
  final configuration = _optionalObject(json, 'audioGuidance');
  return configuration == null
      ? null
      : CourseAudioConfiguration.fromJson(configuration);
}

List<ContentAudioCue> _audioCueList(Map<String, Object?> json, String key) {
  if (!json.containsKey(key)) return const <ContentAudioCue>[];
  final value = json[key];
  if (value is! List<Object?> || value.isEmpty) {
    throw CourseContentFormatException(
      'O evento de áudio "$key" deve ser uma lista não vazia.',
    );
  }
  return List<ContentAudioCue>.unmodifiable(
    value.map((item) {
      if (item is! Map<String, Object?>) {
        throw CourseContentFormatException(
          'Todos os cues de "$key" devem ser objetos.',
        );
      }
      return ContentAudioCue.fromJson(item);
    }),
  );
}

void _validateAudioAsset(String assetPath) {
  if (!assetPath.startsWith('assets/audio/') ||
      assetPath.contains('..') ||
      assetPath.contains('\\') ||
      assetPath.endsWith('/')) {
    throw const CourseContentFormatException(
      'O asset de áudio deve apontar para um arquivo em assets/audio/.',
    );
  }
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
