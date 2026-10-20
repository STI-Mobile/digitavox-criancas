import 'dart:convert';
import 'dart:io';

import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('schema 4 do Módulo 1', () {
    test(
      'interpreta oito missões obrigatórias, bônus e cerimônia separada',
      () {
        final course = _parse();
        final module = course.modules.single;
        expect(course.isDemo, isFalse);
        expect(
          module.lessons.where((lesson) => !lesson.optional),
          hasLength(8),
        );
        expect(module.lessons.where((lesson) => lesson.optional), hasLength(1));
        expect(
          module.lessons.any((lesson) => lesson.id == 'm1-8-cerimonia'),
          isFalse,
        );
        expect(
          module.completionEvent!.prerequisiteLessonId,
          'm1-7-prova-cadete',
        );
        expect(module.completionEvent!.rewardIds.toSet(), {
          'cadete-bronze',
          'blib-blub',
          'zorp',
          'nebulon',
        });
        expect(
          module.lessons.last.prerequisiteEventId,
          module.completionEvent!.id,
        );
        expect(module.lessons[7].legacyLessonIds, [
          'm1-7a-prova-codigo',
          'm1-7b-prova-mensagens',
        ]);
        expect(module.vocabulary.toSet(), {
          'a',
          'da',
          'as',
          'das',
          'ah',
          'sala',
          'fala',
          'asas',
          'gfg',
          'jkj',
          'lçl',
        });
        expect(module.allowedKeys.join(), 'asdfghjklç ');
      },
    );

    test('preserva entradas, repetições e critérios do storyboard', () {
      final lessons = _parse().modules.single.lessons;
      const entries = [
        ['fj', 'jf'],
        ['asdfg', 'gfdsa'],
        ['hjklç', 'çlkjh'],
        ['asdfg hjklç', 'gfdsa çlkjh', 'fgf jhj'],
        ['a as', 'da das'],
        ['ah', 'fala', 'sala', 'asas'],
        ['a sala', 'as asas', 'a fala', 'da sala', 'das asas'],
        ['asdfg çlkjh', 'a fala', 'as asas da sala'],
        ['a as da das ah fala sala asas', 'gfg jkj lçl'],
      ];
      const repetitions = [
        [10, 10],
        [12, 12],
        [12, 12],
        [8, 8, 6],
        [8, 8],
        [8, 8, 8, 8],
        [6, 6, 6, 6, 6],
        [5, 5, 5],
        [1, 1],
      ];
      const criteria = [70, 85, 85, 85, 90, 90, 90, 90, 85];
      const seconds = [15, 12, 12, 12, 10, 10, 10, 8, 5];
      for (var index = 0; index < lessons.length; index++) {
        expect(
          lessons[index].exercises.map((exercise) => exercise.expectedInput),
          entries[index],
        );
        expect(
          lessons[index].exercises.map(
            (exercise) => exercise.minimumRepetitions,
          ),
          repetitions[index],
        );
        expect(lessons[index].accuracy, criteria[index]);
        expect(lessons[index].secChar, seconds[index]);
      }
      expect(lessons[7].exercises.map((exercise) => exercise.spellOut), [
        true,
        false,
        false,
      ]);
    });

    test('distingue ilustrações de cenas e personagens que falam', () {
      final course = _parse();
      expect(course.characters.map((character) => character.id), [
        'stella',
        'zero1',
        'aurora',
      ]);
      expect(
        course.illustrations.map((illustration) => illustration.id),
        contains('scene-c1'),
      );
      expect(
        course.modules.single.lessons.first.scene!.illustrationId,
        'scene-c1',
      );
      expect(course.modules.single.lessons.first.scene!.characterId, 'stella');
      expect(course.modules.single.lessons.first.exercises.first.scene, isNull);
    });

    test(
      'texto canônico resolve narrativa e áudio sem cópias independentes',
      () {
        final json = _document();
        final courseJson = _course(json);
        final resources = (courseJson['audioResources']! as List)
            .cast<Map<String, Object?>>();
        final firstSpeech = resources.firstWhere(
          (cue) => cue['id'] == 'm1c1-stella',
        );
        firstSpeech['text'] = 'Texto revisto da apresentação.';
        final scene = CourseCatalogDocument.fromJson(json)
            .courses
            .single
            .modules
            .single
            .lessons
            .first
            .scene!;
        expect(scene.text, 'Texto revisto da apresentação.');
        expect(scene.narrationCues.single.text, scene.text);
        expect(scene.audioGuidance!.start.first.text, scene.text);
        expect(scene.instructionCues.single.speaker, 'zero1');
        expect(scene.instruction, contains('Indicador esquerdo no F'));
      },
    );

    test(
      'mídia pronta aponta para asset e as demais mantêm fallback explícito',
      () {
        final resources = _parse().audioResources.values;
        expect(resources, isNotEmpty);
        const readyAssets = {
          'm1c1-stella': 'assets/audio/demo/stella/m1c1-stella.mp3',
          'm1c1-zero1': 'assets/audio/demo/zero1/m1c1-zero1.mp3',
        };
        final readyCues = resources.where((cue) => !cue.pending);
        expect({for (final cue in readyCues) cue.id: cue.asset}, readyAssets);
        for (final cue in readyCues) {
          expect(cue.fallback, isNull);
          expect(cue.text, isNotEmpty);
          expect(File(cue.asset!).existsSync(), isTrue);
        }

        for (final cue in resources.where((cue) => cue.pending)) {
          expect(cue.pending, isTrue);
          expect(cue.asset, isNull);
          expect(
            cue.fallback,
            cue.type == ContentAudioCueType.speech
                ? ContentAudioFallback.text
                : cue.id == 'sfx-tecla-incorreta'
                ? ContentAudioFallback.systemClick
                : ContentAudioFallback.silent,
          );
          if (cue.type == ContentAudioCueType.speech) {
            expect(cue.text, isNotEmpty);
          }
        }
        expect(
          resources.where((cue) => cue.id.startsWith('alien-')),
          hasLength(3),
        );
      },
    );

    test('configura atalhos aprovados, convite após três erros e dedos', () {
      final practice = _parse().practice;
      expect(practice.excessiveErrorsThreshold, 3);
      expect(practice.caseSensitive, isFalse);
      expect(practice.shortcuts['F7'], 'repeatExercise');
      expect(practice.shortcuts['F2'], 'nextKey');
      expect(practice.keyFingers['ç'], 'dedo mínimo direito');
      expect(practice.excessiveErrorsCues.single.text, contains('F1'));
      expect(practice.helpCues.single.text, contains('F7 repete o exercício'));
    });

    test(
      'aprova exatamente a média e concede duas estrelas exatamente em 95',
      () {
        final rewards = _parse().rewards;
        for (final minimum in [70, 85, 90]) {
          expect(rewards.starsForAccuracy(minimum - 0.01, minimum), 0);
          expect(rewards.starsForAccuracy(minimum.toDouble(), minimum), 1);
        }
        expect(rewards.starsForAccuracy(94.99, 90), 1);
        expect(rewards.starsForAccuracy(95, 90), 2);
        expect(rewards.starsForAccuracy(99.99, 90), 2);
        expect(rewards.starsForAccuracy(100, 90), 3);
        expect(rewards.starsForAccuracy(double.nan, 90), 0);
        expect(
          rewards.announcementCues[2]!.single.text,
          contains('Duas estrelas'),
        );
        expect(rewards.diaryCues.single.text, 'Relatório de voo do ZERO-1:');
      },
    );

    test('aplica separadores explícitos e fórmula de tempo do storyboard', () {
      final lessons = _parse().modules.single.lessons;
      final first = lessons.first.exercises.first;
      expect(first.completeExpectedInput, List.filled(10, 'fj').join());
      expect(
        first.effectiveTimeLimitSeconds(defaultSecondsPerCharacter: 15),
        449,
      );
      final code = lessons[1].exercises.first;
      expect(code.inputForRepetition(1), 'asdfg ');
      expect(code.inputForRepetition(12), 'asdfg ');
      expect(code.completeExpectedInput, List.filled(12, 'asdfg ').join());
      expect(
        code.effectiveTimeLimitSeconds(defaultSecondsPerCharacter: 12),
        863,
      );
      expect(() => code.inputForRepetition(13), throwsRangeError);
      for (final optional in lessons.last.exercises) {
        expect(optional.inputForRepetition(1).endsWith(' '), isFalse);
        expect(
          optional.effectiveTimeLimitSeconds(defaultSecondsPerCharacter: 5),
          5 * (optional.expectedInput!.runes.length + 1) - 1,
        );
      }
    });

    test('tempo explícito e tempo por caractere substituem defaults', () {
      final json = _document();
      _exercise(json)['timePerCharacterSeconds'] = 2;
      final exercise = _parse(json)
          .modules
          .single
          .lessons
          .first
          .exercises
          .first;
      expect(
        exercise.effectiveTimeLimitSeconds(defaultSecondsPerCharacter: 15),
        59,
      );
      _exercise(json)['timeLimitSeconds'] = 30;
      expect(
        _parse(json).modules.single.lessons.first.exercises.first
            .effectiveTimeLimitSeconds(defaultSecondsPerCharacter: 15),
        30,
      );
    });

    test('filho substitui apenas eventos declarados do áudio herdado', () {
      const parent = CourseAudioConfiguration(
        correctInput: [
          ContentAudioCue(
            id: 'correct',
            type: ContentAudioCueType.speech,
            text: 'Certo.',
          ),
        ],
        incorrectInput: [
          ContentAudioCue(
            id: 'wrong',
            type: ContentAudioCueType.speech,
            text: 'Continue.',
          ),
        ],
      );
      const child = CourseAudioConfiguration(
        start: [
          ContentAudioCue(
            id: 'intro',
            type: ContentAudioCueType.speech,
            text: 'Vamos.',
          ),
        ],
      );
      final resolved = child.inheritFrom(parent);
      expect(resolved.start.single.id, 'intro');
      expect(resolved.correctInput.single.id, 'correct');
      expect(resolved.incorrectInput.single.id, 'wrong');
    });

    final invalidCases = <String, void Function(Map<String, Object?>)>{
      'campo de curso desconhecido': (json) =>
          _course(json)['script'] = 'executar código',
      'campo de prática desconhecido': (json) =>
          (_course(json)['practice']! as Map)['unknown'] = true,
      'campo de cena desconhecido': (json) =>
          (_lesson(json)['scene']! as Map)['text'] = 'cópia desatualizada',
      'campo de exercício desconhecido': (json) =>
          _exercise(json)['soletraexer'] = true,
      'recurso de áudio desconhecido': (json) =>
          (_lesson(json)['scene']! as Map)['narrationCueIds'] = ['missing'],
      'voz desconhecida': (json) =>
          (_course(json)['audioResources']! as List).first['speaker'] =
              'missing',
      'ilustração desconhecida': (json) =>
          (_lesson(json)['scene']! as Map)['illustrationId'] = 'missing',
      'recompensa desconhecida': (json) =>
          (_module(json)['completionEvent']! as Map)['rewardIds'] = ['missing'],
      'pré-requisito desconhecido': (json) =>
          _lesson(json)['prerequisiteLessonIds'] = ['missing'],
      'evento desconhecido': (json) =>
          _lesson(json)['prerequisiteEventId'] = 'missing',
      'alias colide com lição ativa': (json) =>
          _lesson(json)['legacyLessonIds'] = ['m1-7-prova-cadete'],
      'ciclo entre lição e cerimônia': (json) =>
          _lesson(json)['prerequisiteEventId'] = 'm1-decolagem',
      'obrigatório depende de bônus': (json) =>
          _lesson(json)['prerequisiteLessonIds'] = ['m1-9-corrida'],
      'capacidade não executável': (json) => _exercise(json)['type'] = 'timed',
      'tecla fora da linha base': (json) =>
          _exercise(json)['expectedInput'] = 'fe',
      'palavra fora do corpus': (json) =>
          ((_module(json)['lessons']! as List)[4]['exercises'] as List)
                  .first['expectedInput'] =
              'gala',
      'repetições nulas': (json) =>
          _exercise(json)['minimumRepetitions'] = null,
      'tempo explícito nulo': (json) =>
          _exercise(json)['timeLimitSeconds'] = null,
      'tempo por caractere zero': (json) =>
          _exercise(json)['timePerCharacterSeconds'] = 0,
      'soletração não booleana': (json) => _exercise(json)['spellOut'] = 'sim',
      'separador não suportado': (json) =>
          _exercise(json)['repetitionSeparator'] = '\n',
      'faixas de estrelas invertidas': (json) =>
          (_course(json)['rewards']! as Map)['twoStarAccuracy'] = 100,
      'atalho não suportado': (json) =>
          ((_course(json)['practice']! as Map)['shortcuts'] as Map)['F10'] =
              'help',
      'comando não suportado': (json) =>
          ((_course(json)['practice']! as Map)['shortcuts'] as Map)['F1'] =
              'runCode',
      'recurso pendente com asset pronto': (json) =>
          (_course(json)['audioResources']! as List).first['asset'] =
              'assets/audio/not-produced.wav',
      'systemClick usado como voz': (json) =>
          (_course(json)['audioResources']! as List).first['fallback'] =
              'systemClick',
    };
    for (final invalid in invalidCases.entries) {
      test('rejeita ${invalid.key} antes de expor conteúdo à UI', () {
        final json = _document();
        invalid.value(json);
        expect(
          () => _parse(json),
          throwsA(isA<CourseContentFormatException>()),
        );
      });
    }

    test('rejeita IDs de lição repetidos em módulos diferentes', () {
      final json = _document();
      final duplicate =
          jsonDecode(jsonEncode(_module(json))) as Map<String, Object?>;
      duplicate['id'] = 'another-module';
      (_course(json)['modules']! as List).add(duplicate);
      expect(() => _parse(json), throwsA(isA<CourseContentFormatException>()));
    });
  });
}

Map<String, Object?> _document() => jsonDecode(
  File('assets/content/exploradores_espaciais.json').readAsStringSync(),
) as Map<String, Object?>;
Map<String, Object?> _course(Map<String, Object?> json) =>
    (json['courses']! as List).single as Map<String, Object?>;
Map<String, Object?> _module(Map<String, Object?> json) =>
    (_course(json)['modules']! as List).single as Map<String, Object?>;
Map<String, Object?> _lesson(Map<String, Object?> json) =>
    (_module(json)['lessons']! as List).first as Map<String, Object?>;
Map<String, Object?> _exercise(Map<String, Object?> json) =>
    (_lesson(json)['exercises']! as List).first as Map<String, Object?>;
Course _parse([Map<String, Object?>? json]) =>
    CourseCatalogDocument.fromJson(json ?? _document()).courses.single;
