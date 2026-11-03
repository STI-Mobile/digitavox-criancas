import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
import 'package:digitavox_criancas/src/application/audio/audio_guidance.dart';
import 'package:digitavox_criancas/src/application/audio/audio_guidance_services.dart';
import 'package:digitavox_criancas/src/application/course_audio_orchestrator.dart';
import 'package:digitavox_criancas/src/application/course_catalog_view_model.dart';
import 'package:digitavox_criancas/src/application/course_journey_engine.dart';
import 'package:digitavox_criancas/src/application/exercise_session_view_model.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/journey_fixture.dart';
import '../../support/recording_audio_guidance.dart';

void main() {
  late InMemoryProgressRepository repository;
  late CourseCatalogViewModel catalog;
  late CourseJourneyEngine engine;
  late RecordingAudioGuidance audio;

  Future<void> load({bool observePendingEffects = false}) async {
    final json = jsonDecode(
      File('assets/content/exploradores_espaciais.json').readAsStringSync(),
    ) as Map<String, Object?>;
    expect(json['schemaVersion'], 4);
    if (observePendingEffects) {
      // Give the recording adapter synthetic paths so silent pending effects
      // become observable. No media file is loaded or claimed to be packaged.
      // All pedagogical content, ordering and references remain the real JSON.
      final course = (json['courses'] as List).single as Map<String, Object?>;
      for (final resource in course['audioResources'] as List) {
        final cue = resource as Map<String, Object?>;
        if (cue['pending'] == true && cue['type'] != 'speech') {
          cue.remove('pending');
          cue.remove('fallback');
          cue['asset'] = 'assets/audio/test/${cue['id']}.wav';
        }
      }
    }

    catalog = CourseCatalogViewModel(
      courseCatalog: JourneyFixtureCatalog(json),
      progressRepository: repository,
    );
    await catalog.initialize();
    expect(catalog.status, CourseCatalogStatus.ready);
    audio = RecordingAudioGuidance();
    engine = CourseJourneyEngine(
      course: catalog.courses.single,
      catalog: catalog,
      courseAudio: CourseAudioOrchestrator(audioGuidance: audio),
    );
  }

  Future<void> typeCurrentExercise() async {
    final session = engine.session!;
    for (final rune in session.exercise.completeExpectedInput.runes) {
      await session.handleInput(String.fromCharCode(rune));
    }
    expect(session.status, ExerciseSessionStatus.completed);
    expect(session.completionError, isNull);
    // Narration intentionally runs independently of the saved result/outcome.
    await pumpEventQueue();
  }

  int cueCount(String id) =>
      audio.playedCues.where((cue) => cue.id == id).length;

  setUp(() async {
    repository = InMemoryProgressRepository();
    await load();
  });
  tearDown(() async {
    engine.dispose();
    catalog.dispose();
    await audio.dispose();
  });

  test(
    'start and restored progress orient the child at the mission introduction',
    () async {
      final module = engine.course.modules.single;
      final first = module.lessons.first;
      engine.resume();
      await pumpEventQueue();
      expect(engine.stage, JourneyStage.lesson);
      expect(engine.lesson, first);
      expect(engine.session, isNull);
      expect(engine.scene?.text, contains('F e J'));
      engine.openExercise(module, first, first.exercises.first);
      await pumpEventQueue();
      await typeCurrentExercise();
      engine.dispose();
      catalog.dispose();
      await audio.dispose();
      await load();
      engine.resume();
      await pumpEventQueue();
      expect(engine.stage, JourneyStage.lesson);
      expect(engine.session, isNull);
      expect(engine.pendingIn(engine.lesson!)!.id, first.exercises[1].id);
    },
  );

  test(
    'blocks skipping missions, exercises and optional race before the ceremony',
    () {
      final module = engine.course.modules.single;
      final first = module.lessons.first;
      final next = module.lessons[1];
      final race = module.lessons.singleWhere((lesson) => lesson.optional);
      expect(engine.isLessonUnlocked(next), isFalse);
      expect(engine.isLessonUnlocked(race), isFalse);
      expect(() => engine.openLesson(module, next), throwsArgumentError);
      expect(
        () => engine.openExercise(module, first, first.exercises[1]),
        throwsArgumentError,
      );
      expect(() => engine.openLesson(module, race), throwsArgumentError);
    },
  );

  test('eight storyboard missions lead to one ceremony and an optional race', () async {
    engine.dispose();
    catalog.dispose();
    await audio.dispose();
    await load(observePendingEffects: true);
    final module = engine.course.modules.single;
    final missions = module.lessons
        .where((lesson) => !lesson.optional)
        .toList();
    final race = module.lessons.singleWhere((lesson) => lesson.optional);
    final event = module.completionEvent!;
    expect(missions, hasLength(8));
    expect(engine.missionCount, 8);
    final mandatoryExerciseCount = engine.exerciseCount;
    expect(
      mandatoryExerciseCount,
      missions.fold<int>(0, (sum, lesson) => sum + lesson.exercises.length),
    );
    engine.resume();
    await pumpEventQueue();

    for (var missionIndex = 0; missionIndex < missions.length; missionIndex++) {
      final lesson = missions[missionIndex];
      expect(engine.stage, JourneyStage.lesson);
      expect(engine.lesson, lesson);
      expect(engine.session, isNull);
      final completionCueIds =
          lesson.audioGuidance?.completed.map((cue) => cue.id).toList() ??
          <String>[];
      final initialCueCounts = {
        for (final id in completionCueIds) id: cueCount(id),
      };
      final expectedInputs = lesson.exercises.fold<int>(
        0,
        (sum, exercise) => sum + exercise.completeExpectedInput.runes.length,
      );
      engine.openExercise(module, lesson, engine.pendingIn(lesson)!);
      await pumpEventQueue();
      for (
        var exerciseIndex = 0;
        exerciseIndex < lesson.exercises.length;
        exerciseIndex++
      ) {
        final exercise = lesson.exercises[exerciseIndex];
        expect(engine.exercise, exercise);
        expect(engine.character, isNull);
        final isLast = exerciseIndex == lesson.exercises.length - 1;
        await typeCurrentExercise();
        expect(engine.currentLessonAttemptFinished, isLast);
        final saved =
            catalog.progress.courses[engine.course.id]!.lessons[lesson.id]!;
        expect(
          saved.exerciseStatistics[exercise.id]!.totalInputs,
          exercise.completeExpectedInput.runes.length,
        );
        for (final id in completionCueIds) {
          expect(
            cueCount(id),
            initialCueCounts[id]! + (isLast ? 1 : 0),
            reason:
                'Mission effect $id must occur only after the final exercise.',
          );
        }
        if (!isLast) {
          expect(saved.stars, 0);
          engine.continueAfterExercise();
          await pumpEventQueue();
          expect(engine.stage, JourneyStage.exercise);
        }
      }
      expect(engine.currentLessonCompleted, isTrue);
      expect(engine.currentLessonStars, 3);
      expect(engine.currentLessonAverageAccuracy, 100);
      expect(
        engine.currentLessonDiary,
        contains('$expectedInputs teclas digitadas, $expectedInputs corretas'),
      );
      expect(
        audio.playedCues.whereType<SpeechCue>().any(
          (cue) => cue.text.contains('Relatório de voo'),
        ),
        isTrue,
      );
      expect(engine.isLessonUnlocked(race), isFalse);
      engine.continueAfterExercise();
      await pumpEventQueue();
    }

    expect(engine.stage, JourneyStage.moduleCompletion);
    expect(engine.session, isNull); // Ceremony requires no typing exercise.
    expect(engine.exercise, isNull);
    expect(engine.completedMissionCount, 8);
    final beforeReplay = await repository.load();
    final savedCourse = beforeReplay.courses[engine.course.id]!;
    expect(savedCourse.completedEventIds, {event.id});
    expect(savedCourse.unlockedRewardIds, event.rewardIds.toSet());
    expect(savedCourse.unlockedRewardIds, hasLength(4));
    expect(engine.isLessonUnlocked(race), isTrue);
    for (final cue in event.scene!.audioGuidance!.start) {
      expect(cueCount(cue.id), 1);
    }
    await engine.replayModuleEvent();
    await engine.replayModuleEvent();
    expect(await repository.load(), same(beforeReplay));
    expect(
      catalog.progress.courses[engine.course.id]!.unlockedRewardIds,
      hasLength(4),
    );
    await engine.completeModuleEvent();
    expect(engine.stage, JourneyStage.module);
    engine.openLesson(module, race);
    engine.openExercise(module, race, race.exercises.first);
    await pumpEventQueue();
    await typeCurrentExercise();
    engine.continueAfterExercise();
    await pumpEventQueue();
    expect(engine.exercise, race.exercises[1]);
    await typeCurrentExercise();
    expect(engine.missionCount, 8);
    expect(engine.completedMissionCount, 8);
    expect(engine.exerciseCount, mandatoryExerciseCount);
    expect(engine.completedCount, mandatoryExerciseCount);
  });

  test('saved outcome is actionable while narration waits and navigation cancels it', () async {
    engine.dispose();
    await audio.dispose();
    final delayed = _DelayedNarrationGuidance('stella-3estrela');
    audio = delayed.recording;
    engine = CourseJourneyEngine(
      course: catalog.courses.single,
      catalog: catalog,
      courseAudio: CourseAudioOrchestrator(audioGuidance: delayed),
    );
    engine.resume();
    await pumpEventQueue();
    final module = engine.module!;
    final lesson = engine.lesson!;
    engine.openExercise(module, lesson, lesson.exercises.first);
    await pumpEventQueue();
    await typeCurrentExercise();
    engine.continueAfterExercise();
    await pumpEventQueue();
    final session = engine.session!;
    final input = session.exercise.completeExpectedInput.runes.toList();
    for (final rune in input.take(input.length - 1)) {
      await session.handleInput(String.fromCharCode(rune));
    }
    var inputFinished = false;
    final lastInput = session.handleInput(String.fromCharCode(input.last));
    unawaited(
      lastInput.then((_) {
        inputFinished = true;
      }),
    );
    await pumpEventQueue();
    expect(delayed.blockedStarted.isCompleted, isTrue);
    expect(delayed.isBlocked, isTrue);
    expect(
      inputFinished,
      isTrue,
      reason: 'Result must not wait for the voice to finish.',
    );
    expect(session.status, ExerciseSessionStatus.completed);
    expect(engine.currentLessonCompleted, isTrue);
    expect(
      catalog.progress.courses[engine.course.id]!.lessons[lesson.id]!.stars,
      3,
    );
    engine.continueAfterExercise();
    await pumpEventQueue();
    expect(engine.stage, JourneyStage.lesson);
    expect(engine.lesson, module.lessons[1]);
    expect(delayed.cancelledWhileBlocked, 1);
    expect(delayed.isBlocked, isFalse);
    expect(
      audio.playedCues.any((cue) => cue.id == 'zero1-diario-intro'),
      isFalse,
      reason: 'A cancelled celebration must not leak its diary into the next mission.',
    );
    expect(audio.playedCues.any((cue) => cue.id == 'm1c2-stella'), isTrue);
    await lastInput;
  });

  test(
    'wrong keys and unavailable sound preserve practice and saved error pairs',
    () async {
      audio.playFailure = const AudioGuidanceException('asset ausente');
      engine.resume();
      await pumpEventQueue();
      final module = engine.module!;
      final lesson = engine.lesson!;
      final exercise = lesson.exercises.first;
      engine.openExercise(module, lesson, exercise);
      await pumpEventQueue();
      final session = engine.session!;
      final input = exercise.completeExpectedInput.runes.toList();
      await session.handleInput('j'); // First expected key is F.
      expect(session.inputIndex, 1);
      expect(session.status, ExerciseSessionStatus.incorrectAnswer);
      for (final rune in input.skip(1)) {
        await session.handleInput(String.fromCharCode(rune));
      }
      expect(session.status, ExerciseSessionStatus.completed);
      expect(session.completionError, isNull);
      final stats = catalog
          .progress
          .courses[engine.course.id]!
          .lessons[lesson.id]!
          .exerciseStatistics[exercise.id]!;
      expect(stats.totalInputs, input.length);
      expect(stats.correctInputs, input.length - 1);
      expect(stats.errorPairs, {'f → j': 1});
      engine.continueAfterExercise();
      await pumpEventQueue();
      expect(engine.exercise, lesson.exercises[1]);
      await typeCurrentExercise();
      expect(engine.currentLessonCompleted, isTrue);
      expect(engine.currentLessonStars, 2);
      expect(engine.currentLessonDiary, contains('f → j: 1'));
    },
  );
}

/// The final celebration stays pending until navigation asks the audio service
/// to cancel it. This simulates a real utterance rather than instant playback.
final class _DelayedNarrationGuidance implements AudioGuidance {
  _DelayedNarrationGuidance(this.blockedCueId);
  final String blockedCueId;
  final RecordingAudioGuidance recording = RecordingAudioGuidance();
  final Completer<void> blockedStarted = Completer<void>();
  Completer<void>? _blocked;
  int cancelledWhileBlocked = 0;
  bool get isBlocked => _blocked != null && !_blocked!.isCompleted;

  @override
  Future<void> play(AudioCue cue) => playSequence([cue]);
  @override
  Future<void> playSequence(Iterable<AudioCue> cues) async {
    final sequence = cues.toList();
    await recording.playSequence(sequence);
    if (sequence.any((cue) => cue.id == blockedCueId)) {
      _blocked = Completer<void>();
      if (!blockedStarted.isCompleted) blockedStarted.complete();
      await _blocked!.future;
    }
  }

  @override
  Future<void> cancelSequence() async {
    if (isBlocked) {
      cancelledWhileBlocked++;
      _blocked!.complete();
    }
    await recording.cancelSequence();
  }

  @override
  Future<void> stop() => recording.stop();
  @override
  Future<void> dispose() async {
    await cancelSequence();
    await recording.dispose();
  }
}
