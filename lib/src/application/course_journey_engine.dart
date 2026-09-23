import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/content/course_catalog.dart';
import 'audio/audio_coordinator.dart';
import 'course_catalog_view_model.dart';
import 'exercise_session_view_model.dart';
import 'exercise_sound_feedback.dart';

enum JourneyStage { course, module, lesson, exercise }

typedef JourneyExercise = ({
  CourseModule module,
  Lesson lesson,
  Exercise exercise,
});

/// Interprets the validated catalog. Widgets render the current state and send
/// commands; order, resumption, availability and narrative belong here.
final class CourseJourneyEngine extends ChangeNotifier {
  CourseJourneyEngine({
    required this.course,
    required this.catalog,
    required this.audio,
    required this.soundFeedback,
  }) {
    catalog.addListener(_changed);
  }

  final Course course;
  final CourseCatalogViewModel catalog;
  final AudioCoordinator audio;
  final ExerciseSoundFeedback soundFeedback;

  JourneyStage _stage = JourneyStage.course;
  CourseModule? _module;
  Lesson? _lesson;
  Exercise? _exercise;
  ExerciseSessionViewModel? _session;
  bool _disposed = false;

  JourneyStage get stage => _stage;
  CourseModule? get module => _module;
  Lesson? get lesson => _lesson;
  Exercise? get exercise => _exercise;
  ExerciseSessionViewModel? get session => _session;
  bool get canGoBack => _stage != JourneyStage.course;
  String get locationKey =>
      '${course.id}/${_module?.id}/${_lesson?.id}/${_exercise?.id}';
  String get title =>
      _exercise?.title ?? _lesson?.title ?? _module?.title ?? course.title;

  ContentScene? get scene => switch (_stage) {
    JourneyStage.course => course.scene,
    JourneyStage.module => _module!.scene,
    JourneyStage.lesson => _lesson!.scene,
    JourneyStage.exercise => _exercise!.scene,
  };

  ContentAudioReference? get currentAudio =>
      scene?.audio ??
      (_stage == JourneyStage.exercise ? _exercise?.audio : null);

  CourseCharacter? get character {
    final id =
        _exercise?.scene?.characterId ??
        _lesson?.scene?.characterId ??
        _module?.scene?.characterId ??
        course.scene?.characterId;
    for (final character in course.characters) {
      if (character.id == id) return character;
    }
    return null;
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

  bool isAvailable(Exercise exercise) =>
      exercise.type == ExerciseType.key && exercise.expectedInput != null;

  bool isCompleted(Lesson lesson, Exercise exercise) =>
      catalog.isExerciseCompleted(
        courseId: course.id,
        lessonId: lesson.id,
        exerciseId: exercise.id,
      );

  int completedIn(Lesson lesson) => lesson.exercises
      .where((exercise) => isCompleted(lesson, exercise))
      .length;

  int get completedCount => exercises
      .where((target) => isCompleted(target.lesson, target.exercise))
      .length;
  int get exerciseCount => exercises.length;

  JourneyExercise? get resumeTarget {
    for (final target in exercises) {
      if (isAvailable(target.exercise) &&
          !isCompleted(target.lesson, target.exercise)) {
        return target;
      }
    }
    return null;
  }

  Exercise? pendingIn(Lesson lesson) {
    for (final exercise in lesson.exercises) {
      if (isAvailable(exercise) && !isCompleted(lesson, exercise)) {
        return exercise;
      }
    }
    return null;
  }

  JourneyExercise? get nextTarget {
    var found = false;
    for (final target in exercises) {
      if (found &&
          isAvailable(target.exercise) &&
          !isCompleted(target.lesson, target.exercise)) {
        return target;
      }
      if (identical(target.exercise, _exercise)) found = true;
    }
    return null;
  }

  ({CourseModule module, Lesson lesson})? get followingLesson {
    var found = false;
    for (final module in course.modules) {
      for (final lesson in module.lessons) {
        if (found) return (module: module, lesson: lesson);
        if (identical(lesson, _lesson)) found = true;
      }
    }
    return null;
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
    _enter(JourneyStage.lesson, module: module, lesson: lesson);
  }

  void openExercise(CourseModule module, Lesson lesson, Exercise exercise) {
    _validateLesson(module, lesson);
    if (!lesson.exercises.contains(exercise) || !isAvailable(exercise)) {
      throw ArgumentError('Exercício indisponível nesta lição.');
    }
    _enter(
      JourneyStage.exercise,
      module: module,
      lesson: lesson,
      exercise: exercise,
    );
  }

  void resume() {
    final target = resumeTarget;
    if (target != null) {
      openExercise(target.module, target.lesson, target.exercise);
    }
  }

  void continueAfterExercise() {
    if (_session?.status != ExerciseSessionStatus.completed) return;
    final target = nextTarget;
    if (target == null) {
      openLesson(_module!, _lesson!);
    } else if (!identical(target.lesson, _lesson)) {
      // The next lesson is an explicit narrative stop, never an automatic jump.
      openLesson(target.module, target.lesson);
    } else {
      openExercise(target.module, target.lesson, target.exercise);
    }
  }

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
    }
  }

  Future<void> replayNarration() {
    if (_disposed) return Future<void>.value();
    final reference = currentAudio;
    return reference == null ? audio.stop() : audio.playContent(reference);
  }

  Future<void> stopNarration() => audio.stop();

  void _validateLesson(CourseModule module, Lesson lesson) {
    if (!course.modules.contains(module) || !module.lessons.contains(lesson)) {
      throw ArgumentError('Lição fora do módulo.');
    }
  }

  void _enter(
    JourneyStage stage, {
    CourseModule? module,
    Lesson? lesson,
    Exercise? exercise,
  }) {
    if (_disposed) return;
    // Dispose the previous session before starting the next narrative. A delayed
    // widget disposal must never stop audio belonging to a newer location.
    _session?.removeListener(_changed);
    _session?.dispose();
    _session = null;
    _stage = stage;
    _module = module;
    _lesson = lesson;
    _exercise = exercise;
    if (exercise != null && lesson != null) {
      _session = ExerciseSessionViewModel(
        exercise: exercise,
        onCompleted: () => catalog.completeExercise(
          courseId: course.id,
          lessonId: lesson.id,
          exerciseId: exercise.id,
        ),
        soundFeedback: soundFeedback,
        audioCoordinator: audio,
      )..addListener(_changed);
    }
    unawaited(replayNarration());
    notifyListeners();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    catalog.removeListener(_changed);
    _session?.removeListener(_changed);
    _session?.dispose();
    unawaited(audio.stop());
    super.dispose();
  }
}
