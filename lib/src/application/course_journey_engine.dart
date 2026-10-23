import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/content/course_catalog.dart';
import '../domain/progress/student_progress.dart';
import 'course_audio_orchestrator.dart';
import 'course_catalog_view_model.dart';
import 'exercise_session_view_model.dart';

enum JourneyStage { course, module, lesson, exercise, moduleCompletion }

typedef JourneyExercise = ({
  CourseModule module,
  Lesson lesson,
  Exercise exercise,
});
typedef LessonExerciseStatistic = ({String title, int accuracyPercent});

/// Executes validated course data; presentation never decides progression.
final class CourseJourneyEngine extends ChangeNotifier {
  CourseJourneyEngine({
    required this.course,
    required this.catalog,
    required this.courseAudio,
  }) {
    catalog.addListener(_changed);
  }

  final Course course;
  final CourseCatalogViewModel catalog;
  final CourseAudioOrchestrator courseAudio;
  JourneyStage _stage = JourneyStage.course;
  CourseModule? _module;
  Lesson? _lesson;
  Exercise? _exercise;
  ExerciseSessionViewModel? _session;
  var _audioRequestGeneration = 0;
  bool _disposed = false;
  bool _hasStartedLessonAttempt = false;
  String? _moduleCompletionError;
  String? get moduleCompletionError => _moduleCompletionError;
  Set<String> _attemptExerciseIds = <String>{};

  JourneyStage get stage => _stage;
  bool get hasCharacterIntroduction {
    final currentScene = course.scene;
    if (course.isDemo ||
        currentScene == null ||
        currentScene.text.trim().isEmpty ||
        currentScene.instruction.trim().isEmpty) {
      return false;
    }

    bool hasKnownSpeaker(List<ContentAudioCue> cues) => cues.any(
      (cue) =>
          cue.type == ContentAudioCueType.speech &&
          course.characters.any((character) => character.id == cue.speaker),
    );

    return hasKnownSpeaker(currentScene.narrationCues) &&
        hasKnownSpeaker(currentScene.instructionCues);
  }

  CourseModule? get module => _module;
  Lesson? get lesson => _lesson;
  Exercise? get exercise => _exercise;
  ExerciseSessionViewModel? get session => _session;
  bool get canGoBack => _stage != JourneyStage.course;
  String get locationKey =>
      '${_stage.name}/${course.id}/${_module?.id}/${_lesson?.id}/${_exercise?.id}';
  String get title => _stage == JourneyStage.moduleCompletion
      ? completionEvent?.title ?? 'Módulo concluído'
      : _exercise?.title ?? _lesson?.title ?? _module?.title ?? course.title;
  ContentEvent? get completionEvent => _module?.completionEvent;
  bool get moduleCompleted {
    final event = completionEvent;
    if (event != null) {
      return catalog.progress.courses[course.id]?.completedEventIds.contains(
            event.id,
          ) ??
          false;
    }
    return _module?.lessons
            .where((item) => !item.optional)
            .every(isLessonCompleted) ??
        false;
  }

  List<String> get moduleRewardLabels => [
    for (final id in completionEvent?.rewardIds ?? const <String>[])
      for (final reward in course.rewardDefinitions)
        if (reward.id == id) reward.title,
  ];

  ContentScene? get scene => switch (_stage) {
    JourneyStage.course => course.scene,
    JourneyStage.module => _module!.scene,
    JourneyStage.lesson => _lesson!.scene,
    JourneyStage.exercise => _exercise!.scene,
    JourneyStage.moduleCompletion => completionEvent?.scene,
  };

  CourseAudioConfiguration? get _localAudio =>
      scene?.audioGuidance?.inheritFrom(switch (_stage) {
        JourneyStage.course => course.audioGuidance,
        JourneyStage.module => _module!.audioGuidance,
        JourneyStage.lesson => _lesson!.audioGuidance,
        JourneyStage.exercise => _exercise!.audioGuidance,
        JourneyStage.moduleCompletion => completionEvent?.audioGuidance,
      }) ??
      switch (_stage) {
        JourneyStage.course => course.audioGuidance,
        JourneyStage.module => _module!.audioGuidance,
        JourneyStage.lesson => _lesson!.audioGuidance,
        JourneyStage.exercise => _exercise!.audioGuidance,
        JourneyStage.moduleCompletion => completionEvent?.audioGuidance,
      };

  CourseAudioConfiguration? get currentAudioConfiguration {
    if (_stage != JourneyStage.exercise) return _localAudio;
    final inherited =
        (_module?.audioGuidance ?? const CourseAudioConfiguration())
            .inheritFrom(course.audioGuidance);
    final lessonAudio =
        (_lesson?.audioGuidance ?? const CourseAudioConfiguration())
            .inheritFrom(inherited);
    final resolved = (_localAudio ?? const CourseAudioConfiguration())
        .inheritFrom(lessonAudio);
    // Parent feedback may be shared; parent introductions and celebrations
    // belong only to their own stage.
    return CourseAudioConfiguration(
      start: _localAudio?.start ?? const [],
      correctInput: resolved.correctInput,
      incorrectInput: resolved.incorrectInput,
      completed: _localAudio?.completed ?? const [],
    );
  }

  bool get canReplayNarration =>
      courseAudio.hasCues(currentAudioConfiguration, CourseAudioEvent.start);

  /// Illustrations belong to the visible scene, never to an ancestor's practice.
  CourseIllustration? get illustration {
    final id = scene?.illustrationId;
    return course.illustrations.where((image) => image.id == id).firstOrNull;
  }

  CourseCharacter? get character {
    if (_stage == JourneyStage.exercise) return null;
    final id =
        scene?.characterId ??
        _lesson?.scene?.characterId ??
        _module?.scene?.characterId ??
        course.scene?.characterId;
    return course.characters.where((item) => item.id == id).firstOrNull;
  }

  Iterable<JourneyExercise> get exercises sync* {
    for (final module in course.modules) {
      for (final lesson in module.lessons) {
        for (final exercise in lesson.exercises) {
          yield (module: module, lesson: lesson, exercise: exercise);
        }
      }
    }
  }

  Iterable<Lesson> get mandatoryLessons => course.modules
      .expand((module) => module.lessons)
      .where((lesson) => !lesson.optional);
  int get completedMissionCount =>
      mandatoryLessons.where(isLessonCompleted).length;
  int get missionCount => mandatoryLessons.length;
  bool isOptionalLesson(Lesson lesson) => lesson.optional;
  bool isAvailable(Exercise exercise) => switch (exercise.type) {
    ExerciseType.key ||
    ExerciseType.keySequence ||
    ExerciseType.word ||
    ExerciseType.phrase => exercise.expectedInput?.isNotEmpty == true,
    _ => false,
  };

  bool isLessonCompleted(Lesson lesson) =>
      (catalog.progress.courses[course.id]?.lessons[lesson.id]?.stars ?? 0) > 0;
  int earnedStarsFor(Lesson lesson) =>
      catalog.progress.courses[course.id]?.lessons[lesson.id]?.stars ?? 0;
  bool isLessonUnlocked(Lesson lesson) {
    final saved = catalog.progress.courses[course.id];
    final eventId = lesson.prerequisiteEventId;
    if (eventId != null &&
        !(saved?.completedEventIds.contains(eventId) ?? false)) {
      return false;
    }
    return lesson.prerequisiteLessonIds.every(
      (id) => (saved?.lessons[id]?.stars ?? 0) > 0,
    );
  }

  bool isExerciseUnlocked(Lesson lesson, Exercise exercise) {
    if (!isLessonUnlocked(lesson) || !isAvailable(exercise)) return false;
    if (isLessonCompleted(lesson)) return true;
    final index = lesson.exercises.indexOf(exercise);
    return index >= 0 &&
        lesson.exercises.take(index).every((item) => isCompleted(lesson, item));
  }

  bool isCompleted(Lesson lesson, Exercise exercise) =>
      catalog.isExerciseCompleted(
        courseId: course.id,
        lessonId: lesson.id,
        exerciseId: exercise.id,
      );
  int completedIn(Lesson lesson) => lesson.exercises
      .where((exercise) => isCompleted(lesson, exercise))
      .length;
  bool get currentLessonAttemptFinished =>
      _session?.status == ExerciseSessionStatus.completed &&
      (_session!.timeExpired ||
          (_lesson != null &&
              _lesson!.exercises.every(
                (exercise) => _attemptExerciseIds.contains(exercise.id),
              )));
  bool get currentLessonCompleted =>
      currentLessonAttemptFinished && currentLessonStars > 0;
  double get currentLessonAverageAccuracy =>
      catalog
          .progress
          .courses[course.id]
          ?.lessons[_lesson?.id]
          ?.averageAccuracyPercent ??
      0;
  int get currentLessonStars {
    if (_lesson == null || _session?.timeExpired == true) return 0;
    return catalog.progress.courses[course.id]?.lessons[_lesson!.id]
            ?.starsForAccuracy(
              _lesson!.accuracy,
              _lesson!.secChar,
              twoStarsMinimum: course.rewards.twoStarAccuracy,
              threeStarsMinimum: course.rewards.threeStarAccuracy,
            ) ??
        0;
  }

  int get currentLessonTries =>
      catalog.progress.courses[course.id]?.lessons[_lesson?.id]?.tries ?? 0;
  List<LessonExerciseStatistic> get currentLessonExerciseStatistics {
    final lesson = _lesson;
    if (lesson == null) return const [];
    final accuracies =
        catalog
            .progress
            .courses[course.id]
            ?.lessons[lesson.id]
            ?.exerciseAccuracies ??
        const <String, int>{};
    return [
      for (final exercise in lesson.exercises)
        if (accuracies[exercise.id] case final accuracy?)
          (title: exercise.title, accuracyPercent: accuracy),
    ];
  }

  String get currentLessonDiary {
    final saved = catalog.progress.courses[course.id]?.lessons[_lesson?.id];
    var elapsed = 0;
    var inputs = 0;
    var correct = 0;
    final pairs = <String, int>{};
    for (final stats
        in saved?.exerciseStatistics.values ?? const <ExerciseStatistics>[]) {
      elapsed += stats.elapsedMilliseconds;
      inputs += stats.totalInputs;
      correct += stats.correctInputs;
      for (final pair in stats.errorPairs.entries) {
        pairs.update(
          pair.key,
          (count) => count + pair.value,
          ifAbsent: () => pair.value,
        );
      }
    }
    final letters = elapsed == 0 ? 0.0 : inputs * 60000 / elapsed;
    return 'Precisão ${currentLessonAverageAccuracy.toStringAsFixed(1)} por cento.\n '
        '$currentLessonTries ${currentLessonTries == 1 ? 'tentativa' : 'tentativas'} na missão.\n Tempo de prática: ${(elapsed / 1000).round()} segundos.\n '
        '$inputs teclas digitadas, $correct corretas.\n Letras por minuto: ${letters.toStringAsFixed(1)}. \n'
        'Palavras por minuto: ${(letters / 5).toStringAsFixed(1)}. \n Trocas de teclas: ${errorDistributionString(pairs)}.';
  }

  int get completedCount => exercises
      .where(
        (target) =>
            !target.lesson.optional &&
            isCompleted(target.lesson, target.exercise),
      )
      .length;
  int get exerciseCount =>
      exercises.where((target) => !target.lesson.optional).length;
  JourneyExercise? get resumeTarget => exercises
      .where(
        (target) =>
            !target.lesson.optional &&
            isLessonUnlocked(target.lesson) &&
            isAvailable(target.exercise) &&
            !isLessonCompleted(target.lesson) &&
            !isCompleted(target.lesson, target.exercise),
      )
      .firstOrNull;
  Exercise? pendingIn(Lesson lesson) => lesson.exercises
      .where(
        (exercise) =>
            isExerciseUnlocked(lesson, exercise) &&
            !isCompleted(lesson, exercise),
      )
      .firstOrNull;

  JourneyExercise? get nextTarget {
    final currentLesson = _lesson;
    final currentExercise = _exercise;
    if (currentLesson == null || currentExercise == null) return null;
    final index = currentLesson.exercises.indexOf(currentExercise);
    for (final exercise in currentLesson.exercises.skip(index + 1)) {
      if (isAvailable(exercise) && !_attemptExerciseIds.contains(exercise.id)) {
        return (module: _module!, lesson: currentLesson, exercise: exercise);
      }
    }
    final following = followingLesson;
    if (following == null) return null;
    final nextExercise = pendingIn(following.lesson);
    return nextExercise == null
        ? null
        : (
            module: following.module,
            lesson: following.lesson,
            exercise: nextExercise,
          );
  }

  ({CourseModule module, Lesson lesson})? get followingLesson {
    var found = false;
    for (final module in course.modules) {
      for (final lesson in module.lessons) {
        if (found &&
            !lesson.optional &&
            isLessonUnlocked(lesson) &&
            !isLessonCompleted(lesson)) {
          return (module: module, lesson: lesson);
        }
        if (identical(lesson, _lesson)) found = true;
      }
    }
    return null;
  }

  bool get isModuleReadyForCompletion {
    final event = completionEvent;
    return event != null &&
        !moduleCompleted &&
        _module!.lessons
            .where((lesson) => !lesson.optional)
            .every(isLessonCompleted);
  }

  Future<void> start() => replayNarration();
  void openCourse() => _enter(JourneyStage.course);
  void openModule(CourseModule module) {
    if (!course.modules.contains(module)) {
      throw ArgumentError('Módulo fora do curso.');
    }
    _enter(JourneyStage.module, module: module);
  }

  void openLesson(CourseModule module, Lesson lesson) {
    _validateLesson(module, lesson);
    if (!isLessonUnlocked(lesson)) {
      throw ArgumentError('Missão ainda não disponível.');
    }
    _enter(JourneyStage.lesson, module: module, lesson: lesson);
  }

  void openExercise(CourseModule module, Lesson lesson, Exercise exercise) {
    _validateLesson(module, lesson);
    if (!lesson.exercises.contains(exercise) ||
        !isExerciseUnlocked(lesson, exercise)) {
      throw ArgumentError('Exercício indisponível nesta missão.');
    }
    if (_stage != JourneyStage.exercise || !identical(_lesson, lesson)) {
      _hasStartedLessonAttempt = false;
      final completedIds =
          catalog
              .progress
              .courses[course.id]
              ?.lessons[lesson.id]
              ?.completedExerciseIds ??
          const <String>{};
      _attemptExerciseIds = completedIds.length < lesson.exercises.length
          ? Set<String>.from(completedIds)
          : <String>{};
    }
    _enter(
      JourneyStage.exercise,
      module: module,
      lesson: lesson,
      exercise: exercise,
    );
  }

  /// First entry and resumption both preserve mission orientation.
  void resume() {
    final pendingModule = _pendingEventModule;
    if (pendingModule != null) {
      openModuleCompletion(pendingModule);
      return;
    }
    final target = resumeTarget;
    if (target != null) openLesson(target.module, target.lesson);
  }

  CourseModule? get _pendingEventModule => course.modules.where((module) {
    final event = module.completionEvent;
    return event != null &&
        !(catalog.progress.courses[course.id]?.completedEventIds.contains(
              event.id,
            ) ??
            false) &&
        module.lessons
            .where((lesson) => !lesson.optional)
            .every(isLessonCompleted);
  }).firstOrNull;

  void openModuleCompletion(CourseModule module) {
    if (!course.modules.contains(module) ||
        module.completionEvent == null ||
        !module.lessons
            .where((lesson) => !lesson.optional)
            .every(isLessonCompleted)) {
      throw ArgumentError('Conclusão do módulo ainda não disponível.');
    }
    _enter(JourneyStage.moduleCompletion, module: module);
  }

  void continueAfterExercise() {
    if (_session?.status != ExerciseSessionStatus.completed ||
        _lesson == null ||
        _exercise == null) {
      return;
    }
    if (currentLessonAttemptFinished && !currentLessonCompleted) return;
    if (currentLessonCompleted && isModuleReadyForCompletion) {
      _enter(JourneyStage.moduleCompletion, module: _module!);
      return;
    }
    final target = nextTarget;
    if (target == null) {
      if (currentLessonCompleted) {
        openModule(_module!);
      } else {
        openLesson(_module!, _lesson!);
      }
    } else if (!identical(target.lesson, _lesson)) {
      openLesson(target.module, target.lesson);
    } else {
      openExercise(target.module, target.lesson, target.exercise);
    }
  }

  void retryCurrentLesson() {
    if (!currentLessonAttemptFinished ||
        currentLessonCompleted ||
        _module == null ||
        _lesson == null) {
      return;
    }
    final first = _lesson!.exercises.where(isAvailable).firstOrNull;
    if (first == null) return;
    _attemptExerciseIds = <String>{};
    _hasStartedLessonAttempt = false;
    openExercise(_module!, _lesson!, first);
  }

  void retryCurrentExercise() {
    if (_session?.status == ExerciseSessionStatus.completed &&
        _lesson != null &&
        _exercise != null) {
      openExercise(_module!, _lesson!, _exercise!);
    }
  }

  void pausePractice() {
    _session?.pause();
    unawaited(stopNarration());
  }

  void resumePractice() => _session?.resume();
  Future<void> completeModuleEvent() async {
    final module = _module;
    final event = completionEvent;
    if (module == null ||
        event == null ||
        !module.lessons
            .where((lesson) => lesson.id == event.prerequisiteLessonId)
            .any(isLessonCompleted)) {
      return;
    }
    await catalog.recordCourseEvent(
      courseId: course.id,
      eventId: event.id,
      rewardIds: event.rewardIds,
    );
    if (!_disposed && identical(_module, module)) openModule(module);
  }

  bool get hasPendingModuleCompletion => _pendingEventModule != null;

  Future<void> narrateDiary() async {
    final generation = _audioRequestGeneration;
    if (course.rewards.diaryCues.isNotEmpty) {
      await courseAudio.play(
        CourseAudioConfiguration(completed: course.rewards.diaryCues),
        CourseAudioEvent.completed,
      );
    }
    if (_disposed || generation != _audioRequestGeneration) return;
    await courseAudio.speakText(currentLessonDiary);
  }

  Future<void> narrateHelp() => course.practice.helpCues.isEmpty
      ? courseAudio.speakText(_session?.announcement ?? '')
      : courseAudio.play(
          CourseAudioConfiguration(start: course.practice.helpCues),
          CourseAudioEvent.start,
        );

  Future<void> replayModuleEvent() => replayNarration();

  void back() {
    switch (_stage) {
      case JourneyStage.course:
        return;
      case JourneyStage.module:
        openCourse();
      case JourneyStage.lesson:
        openModule(_module!);
      case JourneyStage.exercise:
        openLesson(_module!, _lesson!);
      case JourneyStage.moduleCompletion:
        openModule(_module!);
    }
  }

  Future<void> replayNarration() {
    if (_disposed) return Future<void>.value();
    return _playCurrentNarration(
      ++_audioRequestGeneration,
      explicitlyRequested: true,
    );
  }

  Future<void> stopNarration() {
    ++_audioRequestGeneration;
    return courseAudio.cancel();
  }

  void _validateLesson(CourseModule module, Lesson lesson) {
    if (!course.modules.contains(module) || !module.lessons.contains(lesson)) {
      throw ArgumentError('Missão fora do módulo.');
    }
  }

  void _enter(
    JourneyStage stage, {
    CourseModule? module,
    Lesson? lesson,
    Exercise? exercise,
  }) {
    if (_disposed) return;
    _session?.removeListener(_changed);
    _session?.dispose();
    _session = null;
    _stage = stage;
    _module = module;
    _lesson = lesson;
    _exercise = exercise;
    _moduleCompletionError = null;
    if (exercise != null && lesson != null) {
      final currentSession = ExerciseSessionViewModel(
        exercise: exercise,
        practice: course.practice,
        timeLimitSeconds: exercise.effectiveTimeLimitSeconds(
          defaultSecondsPerCharacter: lesson.secChar > 0
              ? lesson.secChar
              : null,
        ),
        onAttemptStarted: () async {
          if (!_hasStartedLessonAttempt) {
            final saved =
                catalog.progress.courses[course.id]?.lessons[lesson.id];
            if (_attemptExerciseIds.isEmpty &&
                saved?.completedExerciseIds.length == lesson.exercises.length) {
              await catalog.clearLessonAttemptResults(
                courseId: course.id,
                lessonId: lesson.id,
              );
            }
            final tries = await catalog.startLessonAttempt(
              courseId: course.id,
              lessonId: lesson.id,
            );
            _hasStartedLessonAttempt = true;
            return tries;
          }
          return catalog.lessonTries(courseId: course.id, lessonId: lesson.id);
        },
        onCompleted: (accuracyPercent) =>
            _recordCompletion(exercise, lesson, accuracyPercent),
        onInputEvaluated: (correct) => _inputFeedback(correct),
      );
      _session = currentSession..addListener(_changed);
    }
    final generation = ++_audioRequestGeneration;
    unawaited(_replaceNarration(generation));
    notifyListeners();
  }

  Future<void> _inputFeedback(bool correct) async {
    final session = _session;
    if (session == null) return;
    final configuration = currentAudioConfiguration;
    final event = correct
        ? CourseAudioEvent.correctInput
        : CourseAudioEvent.incorrectInput;
    final cues = <ContentAudioCue>[
      ...configuration?.cuesFor(event) ?? const <ContentAudioCue>[],
      if (correct)
        ContentAudioCue(
          id: 'key-echo',
          type: ContentAudioCueType.speech,
          text: _spokenKey(session.lastInput ?? ''),
        ),
      if (!correct &&
          session.consecutiveErrors == course.practice.excessiveErrorsThreshold)
        ...course.practice.excessiveErrorsCues,
    ];
    if (cues.isEmpty) {
      await courseAudio.play(configuration, event);
    } else {
      await courseAudio.play(
        CourseAudioConfiguration(
          correctInput: correct ? cues : const [],
          incorrectInput: correct ? const [] : cues,
        ),
        event,
      );
    }
  }

  Future<void> _recordCompletion(
    Exercise exercise,
    Lesson lesson,
    int accuracyPercent,
  ) async {
    final session = _session;
    if (session == null || !identical(session.exercise, exercise)) return;
    _attemptExerciseIds.add(exercise.id);
    await catalog.recordExerciseResult(
      courseId: course.id,
      lessonId: lesson.id,
      exerciseId: exercise.id,
      accuracyPercent: accuracyPercent,
      lessonAccuracyPercent: lesson.accuracy,
      lessonExerciseIds: lesson.exercises.map((item) => item.id),
      elapsedMilliseconds: session.elapsed.inMilliseconds,
      totalInputs: session.totalInputs,
      correctInputs: session.correctInputs,
      errorPairs: session.errorPairs,
      countsTowardCompletion: !session.timeExpired,
      twoStarsMinimum: course.rewards.twoStarAccuracy,
      threeStarsMinimum: course.rewards.threeStarAccuracy,
    );
    final finished = lesson.exercises.every(
      (item) => _attemptExerciseIds.contains(item.id),
    );
    if (session.timeExpired || (finished && currentLessonStars == 0)) {
      await catalog.clearLessonAttemptResults(
        courseId: course.id,
        lessonId: lesson.id,
      );
    }
    if (_disposed || !identical(_session, session)) return;
    // Saved results become actionable immediately. Narration continues through
    // the coordinator and is cancelled if the child chooses another stage.
    unawaited(_narrateCompletion(session, lesson, finished));
  }

  Future<void> _narrateCompletion(
    ExerciseSessionViewModel session,
    Lesson lesson,
    bool finished,
  ) async {
    final generation = ++_audioRequestGeneration;
    await courseAudio.play(
      currentAudioConfiguration,
      CourseAudioEvent.completed,
    );
    if (_disposed ||
        generation != _audioRequestGeneration ||
        !identical(_session, session)) {
      return;
    }
    if (session.timeExpired) {
      await courseAudio.speakText(
        'O tempo desta prática terminou. Vamos praticar novamente.',
      );
    } else if (finished && currentLessonStars > 0) {
      final lessonAudio =
          lesson.scene?.audioGuidance?.inheritFrom(lesson.audioGuidance) ??
          lesson.audioGuidance;
      if (lessonAudio?.completed.isNotEmpty == true) {
        await courseAudio.play(lessonAudio, CourseAudioEvent.completed);
        if (_disposed || generation != _audioRequestGeneration) return;
      }
      final cues = course.rewards.announcementCues[currentLessonStars];
      if (cues != null && cues.isNotEmpty) {
        await courseAudio.play(
          CourseAudioConfiguration(completed: cues),
          CourseAudioEvent.completed,
        );
      } else {
        await courseAudio.speakText(
          'Missão concluída. Você conquistou $currentLessonStars de 3 estrelas.',
        );
      }
      if (!_disposed && generation == _audioRequestGeneration) {
        await narrateDiary();
      }
    } else {
      await courseAudio.speakText(
        finished
            ? 'Vamos praticar mais. Use a ajuda quando precisar.'
            : 'Exercício concluído. Continue para o próximo exercício.',
      );
    }
  }

  Future<void> _replaceNarration(int generation) async {
    await courseAudio.cancel();
    if (_disposed || generation != _audioRequestGeneration) return;
    await _playCurrentNarration(generation);
  }

  Future<void> _playCurrentNarration(
    int generation, {
    bool explicitlyRequested = false,
  }) async {
    if (_disposed || generation != _audioRequestGeneration) return;
    if (_stage == JourneyStage.moduleCompletion) {
      final event = completionEvent;
      if (event == null) return;
      if (moduleCompleted && !explicitlyRequested) return;
      try {
        await catalog.recordCourseEvent(
          courseId: course.id,
          eventId: event.id,
          rewardIds: event.rewardIds,
        );
      } on Object {
        if (!_disposed && generation == _audioRequestGeneration) {
          _moduleCompletionError =
              'Não foi possível salvar a conclusão. Tente novamente.';
          notifyListeners();
        }
        return;
      }
      if (_disposed || generation != _audioRequestGeneration) return;
    }
    if (_stage == JourneyStage.exercise) {
      final exercise = _exercise!;
      if (canReplayNarration) {
        await courseAudio.play(
          currentAudioConfiguration,
          CourseAudioEvent.start,
        );
      } else {
        final input = exercise.spellOut
            ? exercise.expectedInput!.runes
                  .map((rune) => _spokenKey(String.fromCharCode(rune)))
                  .join(', ')
            : exercise.expectedInput!;
        await courseAudio.speakText('${exercise.prompt} $input');
      }
    } else {
      await courseAudio.play(currentAudioConfiguration, CourseAudioEvent.start);
    }
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_audioRequestGeneration;
    catalog.removeListener(_changed);
    _session?.removeListener(_changed);
    _session?.dispose();
    unawaited(courseAudio.cancel());
    super.dispose();
  }
}

String _spokenKey(String key) => key == ' '
    ? 'barra de espaço'
    : key.toLowerCase() == 'ç'
    ? 'cê-cedilha'
    : key;
