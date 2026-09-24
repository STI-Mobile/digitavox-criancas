import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
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
  late CourseCatalogViewModel catalog;
  late CourseJourneyEngine engine;
  late RecordingAudioGuidance audioGuidance;
  late CourseAudioOrchestrator courseAudio;
  late InMemoryProgressRepository repository;

  setUp(() async {
    repository = InMemoryProgressRepository();
    catalog = CourseCatalogViewModel(
      courseCatalog: JourneyFixtureCatalog(),
      progressRepository: repository,
    );
    await catalog.initialize();
    audioGuidance = RecordingAudioGuidance();
    courseAudio = CourseAudioOrchestrator(audioGuidance: audioGuidance);
    engine = CourseJourneyEngine(
      course: catalog.courses.single,
      catalog: catalog,
      courseAudio: courseAudio,
    );
  });

  tearDown(() async {
    engine.dispose();
    catalog.dispose();
    await audioGuidance.dispose();
  });

  test('follows JSON order and pauses at each new lesson', () async {
    expect(engine.exercises.map((target) => target.exercise.id), [
      'key-f',
      'sequence-fj',
      'key-j',
      'key-a',
      'key-b',
    ]);
    engine.resume();
    expect(engine.exercise!.id, 'key-f');
    await engine.session!.handleInput('f');
    await pumpEventQueue();
    expect(engine.exercise!.id, 'sequence-fj');
    await engine.session!.handleInput('f');
    await engine.session!.handleInput('j');
    await pumpEventQueue();
    expect(engine.exercise!.id, 'key-j');
    expect(engine.session!.status, ExerciseSessionStatus.waitingForInput);
    await engine.session!.handleInput('j');
    await pumpEventQueue();
    expect(engine.stage, JourneyStage.lesson);
    expect(engine.lesson!.id, 'left-hand');
    engine.openExercise(
      engine.module!,
      engine.lesson!,
      engine.pendingIn(engine.lesson!)!,
    );
    await engine.session!.handleInput('a');
    await pumpEventQueue();
    expect(engine.module!.id, 'exploration');
    expect(engine.lesson!.id, 'new-key');
    engine.resume();
    await engine.session!.handleInput('b');
    await pumpEventQueue();
    expect(engine.stage, JourneyStage.lesson);
    expect(engine.resumeTarget, isNull);
    expect(engine.completedCount, 5);
    expect(engine.exerciseCount, 5);
  });

  test(
    'uses array order rather than exercise ids or hard-coded content',
    () async {
      final json = journeyJson();
      final courseJson =
          (json['courses'] as List).single as Map<String, Object?>;
      final modules = courseJson['modules'] as List;
      courseJson['modules'] = modules.reversed.toList();
      final reorderedCatalog = CourseCatalogViewModel(
        courseCatalog: JourneyFixtureCatalog(json),
        progressRepository: InMemoryProgressRepository(),
      );
      await reorderedCatalog.initialize();
      final reorderedEngine = CourseJourneyEngine(
        course: reorderedCatalog.courses.single,
        catalog: reorderedCatalog,
        courseAudio: courseAudio,
      );
      expect(reorderedEngine.resumeTarget!.exercise.id, 'key-b');
      reorderedEngine.dispose();
      reorderedCatalog.dispose();
    },
  );

  test(
    'restores the next pending exercise and does not duplicate completion',
    () async {
      engine.resume();
      final first = engine.exercise!;
      final lesson = engine.lesson!;
      final module = engine.module!;
      await engine.session!.handleInput('f');
      await pumpEventQueue();
      engine.openExercise(module, lesson, first);
      await engine.session!.handleInput('f');
      await pumpEventQueue();
      expect((await repository.load()).totalStars, 1);
      engine.dispose();
      catalog.dispose();
      catalog = CourseCatalogViewModel(
        courseCatalog: JourneyFixtureCatalog(),
        progressRepository: repository,
      );
      await catalog.initialize();
      engine = CourseJourneyEngine(
        course: catalog.courses.single,
        catalog: catalog,
        courseAudio: courseAudio,
      );
      engine.resume();
      expect(engine.exercise!.id, 'sequence-fj');
      engine.back();
      expect(engine.stage, JourneyStage.lesson);
      engine.back();
      expect(engine.stage, JourneyStage.module);
      engine.back();
      expect(engine.stage, JourneyStage.course);
    },
  );

  test(
    'plays each visited scene and resolves inherited and overridden characters',
    () async {
      await engine.start();
      expect(engine.character!.id, 'aurora');
      expect(
        (audioGuidance.playedCues.last as SpeechCue).audioAsset,
        'assets/audio/demo/welcome.wav',
      );
      engine.openModule(engine.course.modules.first);
      await pumpEventQueue();
      expect(
        (audioGuidance.playedCues.last as SpeechCue).audioAsset,
        'assets/audio/demo/preparation.wav',
      );
      engine.openLesson(engine.module!, engine.module!.lessons.first);
      await pumpEventQueue();
      expect(engine.character!.id, 'aurora');
      expect(
        (audioGuidance.playedCues.last as SpeechCue).audioAsset,
        'assets/audio/demo/sensors.wav',
      );
      engine.resume();
      await pumpEventQueue();
      expect(
        (audioGuidance.playedCues.last as SpeechCue).audioAsset,
        'assets/audio/demo/key_f.wav',
      );
      await engine.session!.handleInput('f');
      await pumpEventQueue();
      expect(engine.exercise!.id, 'sequence-fj');
      await engine.session!.handleInput('f');
      await engine.session!.handleInput('j');
      await pumpEventQueue();
      expect(engine.character!.id, 'explorer');
      expect(engine.character!.imageAsset, 'assets/images/demo/explorer.png');
      expect(
        (audioGuidance.playedCues.last as SpeechCue).audioAsset,
        'assets/audio/demo/key_j.wav',
      );
      engine.back();
      await pumpEventQueue();
      expect(engine.character!.id, 'aurora');
      expect(
        (audioGuidance.playedCues.last as SpeechCue).audioAsset,
        'assets/audio/demo/sensors.wav',
      );
      await engine.stopNarration();
      expect(audioGuidance.events.last, 'cancel');
    },
  );

  test(
    'rapid navigation cancels stale audio and does not award progress',
    () async {
      engine.resume();
      final oldSession = engine.session!;
      engine.back();
      engine.back();
      engine.openModule(engine.course.modules.last); // No audio in this scene.
      await oldSession.handleInput('f');
      await pumpEventQueue();
      expect(
        audioGuidance.playedCues.where((cue) => cue.id == 'key-f-start'),
        isEmpty,
      );
      expect(engine.completedCount, 0);
      expect(audioGuidance.events.last, anyOf('stop', 'cancel'));
    },
  );

  test(
    'audio failure does not block navigation, answers or persistence',
    () async {
      audioGuidance.playFailure = const AudioServiceException(
        operation: 'playSequence',
        cause: 'falha simulada',
      );
      engine.resume();
      await pumpEventQueue();
      await engine.session!.handleInput('f');
      await pumpEventQueue();
      expect(engine.exercise!.id, 'sequence-fj');
      expect((await repository.load()).totalStars, 1);
    },
  );

  test(
    'rejects unavailable or foreign targets before changing location',
    () async {
      final json = journeyJson();
      final courses = json['courses'] as List<Object?>;
      final course = courses.single! as Map<String, Object?>;
      final modules = course['modules'] as List<Object?>;
      final moduleJson = modules.first! as Map<String, Object?>;
      final lessons = moduleJson['lessons'] as List<Object?>;
      final lessonJson = lessons.first! as Map<String, Object?>;
      final exercises = lessonJson['exercises'] as List<Object?>;
      final unavailableJson = exercises[1]! as Map<String, Object?>;
      unavailableJson['type'] = 'timed';
      final unavailableCatalog = CourseCatalogViewModel(
        courseCatalog: JourneyFixtureCatalog(json),
        progressRepository: InMemoryProgressRepository(),
      );
      await unavailableCatalog.initialize();
      final unavailableEngine = CourseJourneyEngine(
        course: unavailableCatalog.courses.single,
        catalog: unavailableCatalog,
        courseAudio: courseAudio,
      );
      addTearDown(() {
        unavailableEngine.dispose();
        unavailableCatalog.dispose();
      });
      final unavailableModule = unavailableEngine.course.modules.first;
      final unavailableLesson = unavailableModule.lessons.first;
      final module = engine.course.modules.first;
      expect(
        () => unavailableEngine.openExercise(
          unavailableModule,
          unavailableLesson,
          unavailableLesson.exercises[1],
        ),
        throwsArgumentError,
      );
      expect(
        () => engine.openLesson(
          module,
          engine.course.modules.last.lessons.single,
        ),
        throwsArgumentError,
      );
      expect(engine.stage, JourneyStage.course);
    },
  );
}
