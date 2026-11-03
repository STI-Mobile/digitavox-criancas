part of 'course_catalog.dart';

/// Course choices, independent of platform shortcuts and accessibility APIs.
final class CoursePracticeConfiguration {
  const CoursePracticeConfiguration({
    this.excessiveErrorsThreshold = 3,
    this.caseSensitive = false,
    this.keyFingers = const {},
    this.shortcuts = const {},
    this.helpCues = const [],
    this.excessiveErrorsCues = const [],
  });

  factory CoursePracticeConfiguration.fromJson(Map<String, Object?> json) =>
      CoursePracticeConfiguration(
        excessiveErrorsThreshold: _optionalPositiveInteger(
          json,
          'excessiveErrorsThreshold',
          defaultValue: 3,
        ),
        caseSensitive: _optionalBool(json, 'caseSensitive', false),
        keyFingers: _stringMap(json, 'keyFingers'),
        shortcuts: _stringMap(json, 'shortcuts'),
        helpCues: _optionalCueObjects(json, 'helpCues'),
        excessiveErrorsCues: _optionalCueObjects(json, 'excessiveErrorsCues'),
      );

  final int excessiveErrorsThreshold;
  final bool caseSensitive;
  final Map<String, String> keyFingers;
  final Map<String, String> shortcuts;
  final List<ContentAudioCue> helpCues;
  final List<ContentAudioCue> excessiveErrorsCues;
}

/// Star boundaries are inclusive; precision is aggregated over typed characters.
final class CourseRewardConfiguration {
  const CourseRewardConfiguration({
    this.twoStarAccuracy = 95,
    this.threeStarAccuracy = 100,
    this.announcementCues = const {},
    this.diaryCues = const [],
  });

  factory CourseRewardConfiguration.fromJson(Map<String, Object?> json) {
    final announcements = _optionalObject(json, 'announcementCues') ?? const {};
    return CourseRewardConfiguration(
      twoStarAccuracy: _optionalPercentage(
        json,
        'twoStarAccuracy',
        defaultValue: 95,
      ),
      threeStarAccuracy: _optionalPercentage(
        json,
        'threeStarAccuracy',
        defaultValue: 100,
      ),
      announcementCues: Map.unmodifiable({
        for (final stars in [1, 2, 3])
          if (announcements.containsKey('$stars'))
            stars: _optionalCueObjects(announcements, '$stars'),
      }),
      diaryCues: _optionalCueObjects(json, 'diaryCues'),
    );
  }

  final int twoStarAccuracy;
  final int threeStarAccuracy;
  final Map<int, List<ContentAudioCue>> announcementCues;
  final List<ContentAudioCue> diaryCues;

  int starsForAccuracy(double accuracy, int minimumAccuracy) {
    if (!accuracy.isFinite || accuracy < minimumAccuracy) return 0;
    if (accuracy >= threeStarAccuracy) return 3;
    if (accuracy >= twoStarAccuracy) return 2;
    return 1;
  }
}

final class CourseIllustration {
  const CourseIllustration({
    required this.id,
    required this.title,
    required this.imageAsset,
    required this.imageDescription,
  });

  factory CourseIllustration.fromJson(Map<String, Object?> json) {
    final image = CourseCharacter.fromJson({
      ...json,
      'name': _requiredString(json, 'title'),
    });
    return CourseIllustration(
      id: image.id,
      title: image.name,
      imageAsset: image.imageAsset,
      imageDescription: image.imageDescription,
    );
  }

  final String id;
  final String title;
  final String imageAsset;
  final String imageDescription;
}

enum RewardKind { alien, badge }

final class RewardDefinition {
  const RewardDefinition({
    required this.id,
    required this.title,
    required this.kind,
  });

  factory RewardDefinition.fromJson(Map<String, Object?> json) =>
      RewardDefinition(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
        kind: _enumValue(RewardKind.values, json['kind'], 'kind'),
      );

  final String id;
  final String title;
  final RewardKind kind;
}

/// A narrative ceremony is a course event, never an assessed typing exercise.
final class ContentEvent {
  const ContentEvent({
    required this.id,
    required this.title,
    required this.prerequisiteLessonId,
    this.rewardIds = const [],
    this.scene,
    this.audioGuidance,
  });

  factory ContentEvent.fromJson(Map<String, Object?> json) => ContentEvent(
    id: _requiredString(json, 'id'),
    title: _requiredString(json, 'title'),
    prerequisiteLessonId: _requiredString(json, 'prerequisiteLessonId'),
    rewardIds: _optionalTextList(json, 'rewardIds'),
    scene: _scene(json),
    audioGuidance: _courseAudioConfiguration(json),
  );

  final String id;
  final String title;
  final String prerequisiteLessonId;
  final List<String> rewardIds;
  final ContentScene? scene;
  final CourseAudioConfiguration? audioGuidance;
}

T _enumValue<T extends Enum>(List<T> values, Object? value, String field) {
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw CourseContentFormatException('Valor não suportado em $field: $value.');
}

bool _optionalBool(Map<String, Object?> json, String key, bool defaultValue) {
  if (!json.containsKey(key)) return defaultValue;
  if (json[key] is! bool) {
    throw CourseContentFormatException('$key deve ser booleano.');
  }
  return json[key]! as bool;
}

List<Map<String, Object?>> _optionalObjects(
  Map<String, Object?> json,
  String key,
) => json.containsKey(key) ? _requiredObjectList(json, key) : const [];

List<ContentAudioCue> _optionalCueObjects(
  Map<String, Object?> json,
  String key,
) => List.unmodifiable(
  _optionalObjects(json, key).map(ContentAudioCue.fromJson),
);

List<String> _optionalTextList(
  Map<String, Object?> json,
  String key, {
  bool allowSpace = false,
}) {
  if (!json.containsKey(key)) return const [];
  final value = json[key];
  if (value is! List<Object?> ||
      value.any(
        (item) =>
            item is! String ||
            (item.trim().isEmpty && !(allowSpace && item == ' ')),
      )) {
    throw CourseContentFormatException(
      '$key deve ser uma lista de textos não vazios.',
    );
  }
  final result = value.cast<String>();
  _requireUniqueIds(result, key);
  return List.unmodifiable(result);
}

Map<String, String> _stringMap(Map<String, Object?> json, String key) {
  final object = _optionalObject(json, key) ?? const {};
  if (object.values.any((value) => value is! String || value.trim().isEmpty)) {
    throw CourseContentFormatException(
      '$key deve relacionar nomes a textos não vazios.',
    );
  }
  return Map.unmodifiable(object.cast<String, String>());
}

void _requireKeys(
  Map<String, Object?> json,
  Set<String> supported,
  String kind,
) {
  for (final key in json.keys) {
    if (!supported.contains(key)) {
      throw CourseContentFormatException('Campo desconhecido em $kind: $key.');
    }
  }
}

void _requireFields(
  Map<String, Object?> json,
  Set<String> required,
  String kind,
) {
  for (final key in required) {
    if (!json.containsKey(key)) {
      throw CourseContentFormatException('Campo obrigatório em $kind: $key.');
    }
  }
}

/// Resolves references once, before widgets or the journey can see the catalog.
/// Only known, concrete capabilities are accepted; no executable JSON rules.
Map<String, Object?> _prepareSchema4Course(Map<String, Object?> json) {
  _requireKeys(json, {
    'id',
    'title',
    'version',
    'isDemo',
    'theme',
    'characters',
    'illustrations',
    'audioResources',
    'practice',
    'rewards',
    'rewardDefinitions',
    'scene',
    'audioGuidance',
    'modules',
  }, 'curso');
  _requireFields(json, {
    'id',
    'title',
    'version',
    'isDemo',
    'practice',
    'rewards',
    'modules',
  }, 'curso');
  final resources = _requiredObjectList(json, 'audioResources');
  _requireUniqueIds(
    resources.map((cue) => _requiredString(cue, 'id')),
    'recurso de áudio',
  );
  final cues = {for (final cue in resources) _requiredString(cue, 'id'): cue};
  final characters = _optionalObjects(json, 'characters');
  final illustrations = _optionalObjects(json, 'illustrations');
  final rewards = _optionalObjects(json, 'rewardDefinitions');
  for (final character in characters) {
    _requireKeys(character, {
      'id',
      'name',
      'imageAsset',
      'imageDescription',
    }, 'personagem');
    CourseCharacter.fromJson(character);
  }
  for (final illustration in illustrations) {
    _requireKeys(illustration, {
      'id',
      'title',
      'imageAsset',
      'imageDescription',
    }, 'ilustração');
    CourseIllustration.fromJson(illustration);
  }
  for (final reward in rewards) {
    _requireKeys(reward, {'id', 'title', 'kind'}, 'recompensa');
    RewardDefinition.fromJson(reward);
  }
  _requireUniqueIds(
    illustrations.map((item) => _requiredString(item, 'id')),
    'ilustração',
  );
  _requireUniqueIds(
    rewards.map((item) => _requiredString(item, 'id')),
    'recompensa',
  );
  final characterIds = characters
      .map((item) => _requiredString(item, 'id'))
      .toSet();
  final illustrationIds = illustrations
      .map((item) => _requiredString(item, 'id'))
      .toSet();
  final rewardIds = rewards.map((item) => _requiredString(item, 'id')).toSet();
  for (final resource in resources) {
    final cue = ContentAudioCue.fromJson(resource);
    if (cue.type == ContentAudioCueType.speech && cue.text == null) {
      throw const CourseContentFormatException(
        'Toda fala do schema 4 exige texto canônico acessível.',
      );
    }
    if (cue.speaker != null && !characterIds.contains(cue.speaker)) {
      throw CourseContentFormatException('Voz desconhecida: ${cue.speaker}.');
    }
  }

  List<Map<String, Object?>> resolve(
    Object? raw,
    String field, {
    bool speechOnly = false,
  }) {
    if (raw is! List<Object?> ||
        raw.isEmpty ||
        raw.any((id) => id is! String)) {
      throw CourseContentFormatException(
        '$field exige referências de áudio não vazias.',
      );
    }
    return [
      for (final id in raw)
        if (cues[id] case final cue?)
          if (!speechOnly || cue['type'] == 'speech')
            Map<String, Object?>.from(cue)
          else
            throw CourseContentFormatException('$field aceita apenas falas.')
        else
          throw CourseContentFormatException(
            'Recurso de áudio desconhecido: $id.',
          ),
    ];
  }

  Map<String, Object?>? audio(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map<String, Object?>) {
      throw const CourseContentFormatException(
        'audioGuidance deve ser um objeto.',
      );
    }
    _requireKeys(
      raw,
      CourseAudioEvent.values.map((event) => event.name).toSet(),
      'audioGuidance',
    );
    return {
      for (final entry in raw.entries)
        entry.key: resolve(entry.value, entry.key),
    };
  }

  Map<String, Object?>? scene(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map<String, Object?>) {
      throw const CourseContentFormatException('scene deve ser um objeto.');
    }
    _requireKeys(raw, {
      'narrationCueIds',
      'instructionCueIds',
      'characterId',
      'illustrationId',
    }, 'cena');
    if (!raw.containsKey('narrationCueIds')) {
      throw const CourseContentFormatException(
        'Cena exige narrativa canônica em narrationCueIds.',
      );
    }
    final narration = resolve(raw['narrationCueIds'], 'narrationCueIds');
    final instructions = raw.containsKey('instructionCueIds')
        ? resolve(
            raw['instructionCueIds'],
            'instructionCueIds',
            speechOnly: true,
          )
        : <Map<String, Object?>>[];
    final texts = narration
        .where((cue) => cue['type'] == 'speech')
        .map((cue) => cue['text'] as String?)
        .whereType<String>()
        .join('\n\n');
    if (texts.trim().isEmpty) {
      throw const CourseContentFormatException(
        'Narrativa exige texto acessível, mesmo quando há áudio gravado.',
      );
    }
    final character = _optionalString(raw, 'characterId');
    final illustration = _optionalString(raw, 'illustrationId');
    if (character != null && !characterIds.contains(character)) {
      throw CourseContentFormatException(
        'Personagem desconhecido: $character.',
      );
    }
    if (illustration != null && !illustrationIds.contains(illustration)) {
      throw CourseContentFormatException(
        'Ilustração desconhecida: $illustration.',
      );
    }
    return {
      'text': texts,
      'instruction': instructions
          .map((cue) => cue['text'] as String)
          .join('\n\n'),
      'characterId': ?character,
      'illustrationId': ?illustration,
      'narrationCues': narration,
      'instructionCues': instructions,
      'audioGuidance': {
        'start': [...narration, ...instructions],
      },
    };
  }

  final rawPractice = _optionalObject(json, 'practice')!;
  _requireKeys(rawPractice, {
    'excessiveErrorsThreshold',
    'caseSensitive',
    'keyFingers',
    'shortcuts',
    'helpCueIds',
    'excessiveErrorsCueIds',
  }, 'prática');
  _requireFields(rawPractice, {
    'excessiveErrorsThreshold',
    'caseSensitive',
    'keyFingers',
    'shortcuts',
    'helpCueIds',
    'excessiveErrorsCueIds',
  }, 'prática');
  if (rawPractice['excessiveErrorsThreshold'] is! int ||
      (rawPractice['excessiveErrorsThreshold']! as int) < 1) {
    throw const CourseContentFormatException(
      'Limiar de erros deve ser inteiro positivo.',
    );
  }
  _optionalBool(rawPractice, 'caseSensitive', false);
  final keyFingers = _stringMap(rawPractice, 'keyFingers');
  for (final key in keyFingers.keys) {
    if (!_isSinglePrintableCharacter(key)) {
      throw const CourseContentFormatException(
        'Mapa de dedos exige uma tecla por entrada.',
      );
    }
  }
  final shortcuts = _stringMap(rawPractice, 'shortcuts');
  const commands = {
    'help',
    'nextKey',
    'spellRemaining',
    'remaining',
    'repeatExercise',
    'lessonPresentation',
    'lessonInstruction',
    'currentTime',
    'statistics',
  };
  for (final entry in shortcuts.entries) {
    if (!RegExp(r'^F[1-9]$').hasMatch(entry.key) ||
        !commands.contains(entry.value)) {
      throw CourseContentFormatException(
        'Atalho não suportado: ${entry.key}: ${entry.value}.',
      );
    }
  }
  if (shortcuts.values.toSet().length != shortcuts.length) {
    throw const CourseContentFormatException(
      'Comando duplicado nos atalhos do curso.',
    );
  }
  final practice = {...rawPractice}
    ..remove('helpCueIds')
    ..remove('excessiveErrorsCueIds')
    ..['helpCues'] = resolve(
      rawPractice['helpCueIds'],
      'helpCueIds',
      speechOnly: true,
    )
    ..['excessiveErrorsCues'] = resolve(
      rawPractice['excessiveErrorsCueIds'],
      'excessiveErrorsCueIds',
      speechOnly: true,
    );

  final rawRewards = _optionalObject(json, 'rewards')!;
  _requireKeys(rawRewards, {
    'twoStarAccuracy',
    'threeStarAccuracy',
    'announcementCueIds',
    'diaryCueIds',
  }, 'estrelas');
  _requireFields(rawRewards, {
    'twoStarAccuracy',
    'threeStarAccuracy',
    'announcementCueIds',
  }, 'estrelas');
  for (final field in ['twoStarAccuracy', 'threeStarAccuracy']) {
    if (rawRewards[field] is! int) {
      throw CourseContentFormatException('$field deve ser inteiro.');
    }
    _optionalPercentage(rawRewards, field, defaultValue: 0);
  }
  if ((rawRewards['twoStarAccuracy']! as int) >=
      (rawRewards['threeStarAccuracy']! as int)) {
    throw const CourseContentFormatException(
      'Faixas de estrelas devem crescer.',
    );
  }
  final announcements = _optionalObject(rawRewards, 'announcementCueIds');
  if (announcements == null) {
    throw const CourseContentFormatException(
      'Falas de estrelas são obrigatórias.',
    );
  }
  _requireKeys(announcements, {'1', '2', '3'}, 'falas de estrelas');
  _requireFields(announcements, {'1', '2', '3'}, 'falas de estrelas');
  final rewardConfiguration = {...rawRewards}
    ..remove('announcementCueIds')
    ..remove('diaryCueIds')
    ..['announcementCues'] = {
      for (final entry in announcements.entries)
        entry.key: resolve(
          entry.value,
          'estrelas ${entry.key}',
          speechOnly: true,
        ),
    }
    ..['diaryCues'] = rawRewards.containsKey('diaryCueIds')
        ? resolve(rawRewards['diaryCueIds'], 'diaryCueIds', speechOnly: true)
        : <Map<String, Object?>>[];

  final modules = _requiredObjectList(json, 'modules');
  final lessonById = <String, Map<String, Object?>>{};
  final eventById = <String, Map<String, Object?>>{};
  final moduleLessons = <String, Set<String>>{};
  final exerciseIds = <String>{};
  for (final module in modules) {
    _requireKeys(module, {
      'id',
      'title',
      'allowedKeys',
      'vocabulary',
      'scene',
      'audioGuidance',
      'lessons',
      'completionEvent',
    }, 'módulo');
    _requireFields(module, {'allowedKeys', 'vocabulary', 'lessons'}, 'módulo');
    final moduleId = _requiredString(module, 'id');
    final allowedKeys = _optionalTextList(
      module,
      'allowedKeys',
      allowSpace: true,
    );
    if (allowedKeys.isEmpty ||
        allowedKeys.any((key) => !_isSinglePrintableCharacter(key))) {
      throw const CourseContentFormatException(
        'allowedKeys exige teclas imprimíveis individuais.',
      );
    }
    final vocabulary = _optionalTextList(module, 'vocabulary');
    if (vocabulary.isEmpty) {
      throw const CourseContentFormatException(
        'O módulo exige vocabulário explícito.',
      );
    }
    final allowed = allowedKeys
        .map(
          (key) =>
              rawPractice['caseSensitive'] == true ? key : key.toLowerCase(),
        )
        .toSet();
    final vocabularySet = vocabulary.map((word) => word.toLowerCase()).toSet();
    for (final word in vocabulary) {
      if (word.runes.any(
        (rune) => !allowed.contains(String.fromCharCode(rune).toLowerCase()),
      )) {
        throw const CourseContentFormatException(
          'Vocabulário usa tecla fora de allowedKeys.',
        );
      }
    }
    for (final key in allowedKeys) {
      if (!keyFingers.containsKey(key.toLowerCase())) {
        throw CourseContentFormatException(
          'Dedo não configurado para a tecla $key.',
        );
      }
    }
    final lessons = _requiredObjectList(module, 'lessons');
    moduleLessons[moduleId] = lessons
        .map((lesson) => _requiredString(lesson, 'id'))
        .toSet();
    for (final lesson in lessons) {
      _requireKeys(lesson, {
        'id',
        'title',
        'accuracy',
        'secChar',
        'prerequisiteLessonIds',
        'prerequisiteEventId',
        'legacyLessonIds',
        'optional',
        'scene',
        'audioGuidance',
        'exercises',
      }, 'lição');
      _requireFields(lesson, {
        'accuracy',
        'secChar',
        'prerequisiteLessonIds',
        'optional',
        'exercises',
      }, 'lição');
      final lessonId = _requiredString(lesson, 'id');
      if (lessonById.containsKey(lessonId)) {
        throw CourseContentFormatException(
          'ID de lição duplicado no curso: $lessonId.',
        );
      }
      lessonById[lessonId] = lesson;
      if (lesson['accuracy'] is! int || lesson['secChar'] is! int) {
        throw const CourseContentFormatException(
          'accuracy e secChar devem ser inteiros no schema 4.',
        );
      }
      _optionalPercentage(lesson, 'accuracy', defaultValue: 0);
      _optionalPositiveInteger(lesson, 'secChar', defaultValue: 0);
      if ((lesson['accuracy']! as int) >
          (rawRewards['twoStarAccuracy']! as int)) {
        throw const CourseContentFormatException(
          'A média mínima não pode exceder a faixa de duas estrelas.',
        );
      }
      _optionalBool(lesson, 'optional', false);
      _optionalTextList(lesson, 'prerequisiteLessonIds');
      for (final exercise in _requiredObjectList(lesson, 'exercises')) {
        _requireKeys(exercise, {
          'id',
          'title',
          'type',
          'prompt',
          'expectedInput',
          'minimumRepetitions',
          'spellOut',
          'repetitionSeparator',
          'trailingSeparator',
          'timePerCharacterSeconds',
          'timeLimitSeconds',
          'audioGuidance',
          'scene',
        }, 'exercício');
        _requireFields(exercise, {
          'expectedInput',
          'minimumRepetitions',
          'spellOut',
          'repetitionSeparator',
          'trailingSeparator',
        }, 'exercício');
        final exerciseId = _requiredString(exercise, 'id');
        if (!exerciseIds.add(exerciseId)) {
          throw CourseContentFormatException(
            'ID de exercício duplicado no curso: $exerciseId.',
          );
        }
        if (!{
          'key',
          'keySequence',
          'word',
          'phrase',
        }.contains(exercise['type'])) {
          throw const CourseContentFormatException(
            'Tipo de exercício sem capacidade executável no schema 4.',
          );
        }
        for (final field in ['minimumRepetitions', 'timeLimitSeconds']) {
          if (exercise.containsKey(field) &&
              (exercise[field] is! int || (exercise[field]! as int) < 1)) {
            throw CourseContentFormatException(
              '$field exige inteiro positivo no schema 4.',
            );
          }
        }
        final expected = exercise['expectedInput'];
        if (expected is! String ||
            expected.isEmpty ||
            expected.runes.any(
              (rune) => !_isSinglePrintableCharacter(String.fromCharCode(rune)),
            )) {
          throw const CourseContentFormatException(
            'Exercício exige entrada imprimível não vazia.',
          );
        }
        _optionalBool(exercise, 'spellOut', false);
        for (final field in ['repetitionSeparator', 'trailingSeparator']) {
          if (exercise[field] != '' && exercise[field] != ' ') {
            throw CourseContentFormatException(
              '$field permite apenas vazio ou espaço.',
            );
          }
        }
        if (exercise.containsKey('timePerCharacterSeconds')) {
          if (exercise['timePerCharacterSeconds'] is! int) {
            throw const CourseContentFormatException(
              'Tempo por caractere deve ser inteiro.',
            );
          }
          _optionalPositiveInteger(
            exercise,
            'timePerCharacterSeconds',
            defaultValue: 0,
          );
        }
        final stream =
            '$expected${exercise['repetitionSeparator']}${exercise['trailingSeparator']}';
        if (stream.runes.any(
          (rune) => !allowed.contains(
            rawPractice['caseSensitive'] == true
                ? String.fromCharCode(rune)
                : String.fromCharCode(rune).toLowerCase(),
          ),
        )) {
          throw CourseContentFormatException(
            'Exercício $exerciseId usa tecla fora de allowedKeys.',
          );
        }
        if ({'word', 'phrase'}.contains(exercise['type']) &&
            expected
                .split(' ')
                .where((word) => word.isNotEmpty)
                .any((word) => !vocabularySet.contains(word.toLowerCase()))) {
          throw CourseContentFormatException(
            'Exercício $exerciseId usa palavra fora do vocabulário.',
          );
        }
      }
    }
    final event = _optionalObject(module, 'completionEvent');
    if (event != null) {
      _requireKeys(event, {
        'id',
        'title',
        'prerequisiteLessonId',
        'rewardIds',
        'scene',
        'audioGuidance',
      }, 'evento de conclusão');
      _requireFields(event, {
        'id',
        'title',
        'prerequisiteLessonId',
        'rewardIds',
        'scene',
      }, 'evento de conclusão');
      final id = _requiredString(event, 'id');
      if (eventById.containsKey(id)) {
        throw CourseContentFormatException('Evento duplicado: $id.');
      }
      eventById[id] = event;
      if (!moduleLessons[moduleId]!.contains(
        _requiredString(event, 'prerequisiteLessonId'),
      )) {
        throw const CourseContentFormatException(
          'Pré-requisito da cerimônia deve pertencer ao módulo.',
        );
      }
      for (final reward in _optionalTextList(event, 'rewardIds')) {
        if (!rewardIds.contains(reward)) {
          throw CourseContentFormatException(
            'Recompensa desconhecida: $reward.',
          );
        }
      }
    }
  }
  final graph = <String, List<String>>{};
  final legacyIds = <String>{};
  for (final entry in lessonById.entries) {
    for (final alias in _optionalTextList(entry.value, 'legacyLessonIds')) {
      if (lessonById.containsKey(alias) || !legacyIds.add(alias)) {
        throw CourseContentFormatException(
          'Alias legado colide com outro ID de lição: $alias.',
        );
      }
    }
    final prerequisites = _optionalTextList(
      entry.value,
      'prerequisiteLessonIds',
    );
    for (final id in prerequisites) {
      if (!lessonById.containsKey(id)) {
        throw CourseContentFormatException(
          'Pré-requisito de lição desconhecido: $id.',
        );
      }
      if (entry.value['optional'] != true &&
          lessonById[id]!['optional'] == true) {
        throw const CourseContentFormatException(
          'Conteúdo obrigatório não pode depender do bônus.',
        );
      }
    }
    final eventId = _optionalString(entry.value, 'prerequisiteEventId');
    if (eventId != null && !eventById.containsKey(eventId)) {
      throw CourseContentFormatException(
        'Pré-requisito de evento desconhecido: $eventId.',
      );
    }
    graph['lesson:${entry.key}'] = [
      for (final id in prerequisites) 'lesson:$id',
      if (eventId != null) 'event:$eventId',
    ];
  }
  for (final entry in eventById.entries) {
    final prerequisite = _requiredString(entry.value, 'prerequisiteLessonId');
    if (lessonById[prerequisite]!['optional'] == true) {
      throw const CourseContentFormatException(
        'Cerimônia de módulo não pode depender do bônus.',
      );
    }
    graph['event:${entry.key}'] = ['lesson:$prerequisite'];
  }
  final visiting = <String>{};
  final visited = <String>{};
  void visit(String id) {
    if (visited.contains(id)) return;
    if (!visiting.add(id)) {
      throw const CourseContentFormatException(
        'Ciclo nos pré-requisitos do curso.',
      );
    }
    for (final target in graph[id] ?? const <String>[]) {
      visit(target);
    }
    visiting.remove(id);
    visited.add(id);
  }

  for (final id in graph.keys) {
    visit(id);
  }

  Map<String, Object?> expandNode(Map<String, Object?> node) => {
    ...node,
    if (node['audioGuidance'] != null)
      'audioGuidance': audio(node['audioGuidance']),
    if (node['scene'] != null) 'scene': scene(node['scene']),
  };
  return {
    ...expandNode(json),
    'practice': practice,
    'rewards': rewardConfiguration,
    'modules': [
      for (final module in modules)
        {
          ...expandNode(module),
          if (module['completionEvent'] != null)
            'completionEvent': expandNode(
              _optionalObject(module, 'completionEvent')!,
            ),
          'lessons': [
            for (final lesson in _requiredObjectList(module, 'lessons'))
              {
                ...expandNode(lesson),
                'exercises': [
                  for (final exercise in _requiredObjectList(
                    lesson,
                    'exercises',
                  ))
                    expandNode(exercise),
                ],
              },
          ],
        },
    ],
  };
}
