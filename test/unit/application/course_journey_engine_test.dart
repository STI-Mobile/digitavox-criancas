import 'package:digitavox_criancas/src/application/audio/audio_coordinator.dart';
import 'package:digitavox_criancas/src/application/audio/content_audio_service.dart';
import 'package:digitavox_criancas/src/application/course_catalog_view_model.dart';
import 'package:digitavox_criancas/src/application/course_journey_engine.dart';
import 'package:digitavox_criancas/src/application/exercise_session_view_model.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_content_audio_service.dart';
import '../../support/journey_fixture.dart';

void main() {
  late CourseCatalogViewModel catalog;
  late CourseJourneyEngine engine;
  late FakeContentAudioService service;
  late AudioCoordinator audio;
  late InMemoryProgressRepository repository;

  setUp(() async {
    repository = InMemoryProgressRepository();
    catalog = CourseCatalogViewModel(
      courseCatalog: JourneyFixtureCatalog(),
      progressRepository: repository,
    );
    await catalog.initialize();
    service = FakeContentAudioService();
    audio = AudioCoordinator(contentAudioService: service);
    engine = CourseJourneyEngine(
      course: catalog.courses.single,
      catalog: catalog,
      audio: audio,
      soundFeedback: SilentExerciseFeedback(),
    );
  });

  tearDown(() async {
    engine.dispose();
    catalog.dispose();
    await audio.dispose();
  });

  test('follows JSON order across lessons and modules, skipping unsupported execution', () async {
    expect(engine.exercises.map((target) => target.exercise.id), [
      'key-f',
      'sequence-fj',
      'key-j',
      'key-a',
      'key-b',
    ]);
    engine.resume();
    engine.continueAfterExercise();
    expect(engine.exercise!.id, 'key-f');
    await engine.session!.handleInput('f');
    engine.continueAfterExercise();
    expect(engine.exercise!.id, 'key-j');
    expect(engine.session!.status, ExerciseSessionStatus.waitingForInput);
    await engine.session!.handleInput('j');
    engine.continueAfterExercise();
    expect(engine.stage, JourneyStage.lesson);
    expect(engine.lesson!.id, 'left-hand');
    engine.openExercise(
      engine.module!,
      engine.lesson!,
      engine.pendingIn(engine.lesson!)!,
    );
    await engine.session!.handleInput('a');
    engine.continueAfterExercise();
    expect(engine.module!.id, 'exploration');
    expect(engine.lesson!.id, 'new-key');
    engine.resume();
    await engine.session!.handleInput('b');
    engine.continueAfterExercise();
    expect(engine.stage, JourneyStage.lesson);
    expect(engine.resumeTarget, isNull);
    expect(engine.completedCount, 4);
    expect(engine.exerciseCount, 5); // Unsupported is not falsely completed.
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
        audio: audio,
        soundFeedback: SilentExerciseFeedback(),
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
      engine.openExercise(module, lesson, first);
      await engine.session!.handleInput('f');
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
        audio: audio,
        soundFeedback: SilentExerciseFeedback(),
      );
      engine.resume();
      expect(engine.exercise!.id, 'key-j');
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
      expect(service.events.last, 'play:assets/audio/demo/welcome.wav');
      engine.openModule(engine.course.modules.first);
      await pumpEventQueue();
      expect(service.events.last, 'play:assets/audio/demo/preparation.wav');
      engine.openLesson(engine.module!, engine.module!.lessons.first);
      await pumpEventQueue();
      expect(engine.character!.id, 'aurora');
      expect(service.events.last, 'play:assets/audio/demo/sensors.wav');
      engine.resume();
      await pumpEventQueue();
      expect(service.events.last, 'play:assets/audio/demo/key_f.wav');
      await engine.session!.handleInput('f');
      engine.continueAfterExercise();
      await pumpEventQueue();
      expect(engine.character!.id, 'explorer');
      expect(engine.character!.imageAsset, 'assets/images/demo/explorer.png');
      expect(service.events.last, 'play:assets/audio/demo/key_j.wav');
      engine.back();
      await pumpEventQueue();
      expect(engine.character!.id, 'aurora');
      expect(service.events.last, 'play:assets/audio/demo/sensors.wav');
      await engine.stopNarration();
      expect(service.events.last, 'stop');
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
        service.events.where((event) => event.startsWith('play:')),
        isEmpty,
      );
      expect(engine.completedCount, 0);
      expect(service.events.last, 'stop');
    },
  );

  test(
    'audio failure does not block navigation, answers or persistence',
    () async {
      service.playFailure = const ContentAudioPlaybackException(
        operation: 'play',
        cause: 'missing asset',
      );
      engine.resume();
      await pumpEventQueue();
      expect(audio.lastFailure, isNotNull);
      await engine.session!.handleInput('f');
      engine.continueAfterExercise();
      expect(engine.exercise!.id, 'key-j');
      expect((await repository.load()).totalStars, 1);
    },
  );

  test('rejects unavailable or foreign targets before changing location', () {
    final module = engine.course.modules.first;
    final lesson = module.lessons.first;
    expect(
      () => engine.openExercise(module, lesson, lesson.exercises[1]),
      throwsArgumentError,
    );
    expect(
      () =>
          engine.openLesson(module, engine.course.modules.last.lessons.single),
      throwsArgumentError,
    );
    expect(engine.stage, JourneyStage.course);
  });
}
