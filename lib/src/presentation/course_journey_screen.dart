import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/course_journey_engine.dart';
import '../domain/content/course_catalog.dart';
import '../domain/progress/student_progress.dart';
import 'course_navigation_tile.dart';
import 'course_scene.dart';
import 'design_system/components/dvx_game_components.dart';
import 'design_system/course_theme/course_theme.dart';
import 'exercise_screen.dart';
import 'keyboard_navigation.dart';

final class CourseJourneyScreen extends StatefulWidget {
  const CourseJourneyScreen({
    required this.engine,
    required this.onThemePreferenceChanged,
    super.key,
  });

  final CourseJourneyEngine engine;
  final ValueChanged<AppThemePreference> onThemePreferenceChanged;

  @override
  State<CourseJourneyScreen> createState() => _CourseJourneyScreenState();
}

final class _CourseJourneyScreenState extends State<CourseJourneyScreen> {
  bool _courseIntroductionComplete = false;

  CourseJourneyEngine get engine => widget.engine;

  CourseCharacter? _characterFor(List<ContentAudioCue> cues) {
    final speaker = cues
        .where((cue) => cue.type == ContentAudioCueType.speech)
        .map((cue) => cue.speaker)
        .whereType<String>()
        .firstOrNull;
    return widget.engine.course.characters
        .where((character) => character.id == speaker)
        .firstOrNull;
  }

  Future<void> _selectTheme(AppThemePreference preference) async {
    await widget.engine.catalog.updateThemePreference(preference);
    widget.onThemePreferenceChanged(preference);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        widget.engine.canGoBack) {
      widget.engine.back();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.engine,
    builder: (context, _) => KeyboardNavigation(
      key: ValueKey('keyboard-${widget.engine.locationKey}'),
      onNavigate: () => unawaited(widget.engine.stopNarration()),
      onAnnounce: widget.engine.courseAudio.speakText,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: _handleKeyEvent,
        child: PopScope(
          canPop: !widget.engine.canGoBack,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) widget.engine.back();
          },
          child: Builder(
            builder: (context) {
              final preference =
                  widget.engine.catalog.progress.settings.themePreference;
              final courseTheme = DvxCourseThemes.resolve(
                widget.engine.course.themeId,
              ).resolve(preference);
              return DvxGameScaffold(
                courseTheme: courseTheme,
                bottomNavigationBar: widget.engine.stage == JourneyStage.lesson
                    ? Builder(
                        builder: (context) =>
                            _missionFooter(context) ?? const SizedBox.shrink(),
                      )
                    : null,
                leading: widget.engine.canGoBack
                    ? KeyboardNavigationLabel(
                        label: switch (widget.engine.stage) {
                          JourneyStage.exercise => 'Voltar à missão',
                          JourneyStage.lesson ||
                          JourneyStage.moduleCompletion => 'Voltar ao módulo',
                          _ => 'Voltar ao curso',
                        },
                        child: IconButton(
                          onPressed: widget.engine.back,
                          tooltip: switch (widget.engine.stage) {
                            JourneyStage.exercise => 'Voltar à missão',
                            JourneyStage.lesson ||
                            JourneyStage.moduleCompletion => 'Voltar ao módulo',
                            _ => 'Voltar ao curso',
                          },
                          icon: const Icon(Icons.arrow_back),
                        ),
                      )
                    : null,
                title: switch (widget.engine.stage) {
                  JourneyStage.course => 'Digitavox',
                  JourneyStage.module => 'Módulo',
                  JourneyStage.lesson => 'Missão',
                  JourneyStage.exercise =>
                    widget.engine.currentLessonCompleted
                        ? 'Missão concluída'
                        : widget.engine.lesson!.title,
                  JourneyStage.moduleCompletion => 'Conclusão do módulo',
                },
                actions: widget.engine.stage == JourneyStage.exercise
                    ? const <Widget>[]
                    : [
                        DvxThemeSelector(
                          preference: preference,
                          onSelected: _selectTheme,
                          onAnnounce: widget.engine.courseAudio.speakText,
                        ),
                      ],
                body: Builder(
                  builder: (context) {
                    return Semantics(
                      key: ValueKey(widget.engine.locationKey),
                      scopesRoute: true,
                      namesRoute: true,
                      label:
                          widget.engine.stage == JourneyStage.exercise &&
                              widget.engine.currentLessonCompleted
                          ? 'Missão concluída. ${widget.engine.lesson!.title}'
                          : widget.engine.title,
                      explicitChildNodes: true,
                      child: SingleChildScrollView(
                        key: PageStorageKey(widget.engine.locationKey),
                        padding: EdgeInsets.all(context.courseTheme.spacing.lg),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.engine.stage !=
                                    JourneyStage.exercise) ...[
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      widget.engine.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                  ),
                                  SizedBox(
                                    height: context.courseTheme.spacing.md,
                                  ),
                                ],
                                if (widget.engine.stage ==
                                    JourneyStage.lesson) ...[
                                  CourseScene(
                                    scene: widget.engine.scene,
                                    character: widget.engine.character,
                                    illustration: widget.engine.illustration,
                                  ),
                                  ..._narrationControls(context),
                                ],
                                ...switch (widget.engine.stage) {
                                  JourneyStage.course => _course(context),
                                  JourneyStage.module => _module(context),
                                  JourneyStage.lesson => _lesson(context),
                                  JourneyStage.moduleCompletion => [
                                    _ModuleCompletion(engine: widget.engine),
                                  ],
                                  JourneyStage.exercise => [
                                    ExerciseScreen(
                                      key: ValueKey(widget.engine.session),
                                      engine: widget.engine,
                                    ),
                                  ],
                                },
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  List<Widget> _course(BuildContext context) {
    final spacing = context.courseTheme.spacing;
    final engine = widget.engine;
    if (!_courseIntroductionComplete && engine.hasCharacterIntroduction) {
      final scene = engine.scene!;
      final firstCues = scene.narrationCues
          .where((cue) => cue.type == ContentAudioCueType.speech)
          .toList(growable: false);
      final secondCues = scene.instructionCues
          .where((cue) => cue.type == ContentAudioCueType.speech)
          .toList(growable: false);
      final firstCharacter = _characterFor(firstCues)!;
      final secondCharacter = _characterFor(secondCues)!;
      return [
        _CourseIntroduction(
          engine: engine,
          firstCharacter: firstCharacter,
          firstText: scene.text,
          firstCues: firstCues,
          secondCharacter: secondCharacter,
          secondText: scene.instruction,
          secondCues: secondCues,
          onComplete: () => setState(() => _courseIntroductionComplete = true),
          narrationControls: ({cues}) =>
              _narrationControls(context, cues: cues),
        ),
      ];
    }

    final target = engine.resumeTarget;
    return [
      if (engine.course.isDemo) ...[
        Semantics(
          label: 'Aviso: conteúdo de demonstração, não é conteúdo pedagógico definitivo.',
          child: const Text('DEMO'),
        ),
        SizedBox(height: spacing.md),
      ],
      if (engine.scene != null) ...[
        Text(engine.scene!.text),
        SizedBox(height: spacing.sm),
        ..._narrationControls(context),
      ],
      Text(
        '${engine.completedMissionCount} de ${engine.missionCount} missões concluídas',
      ),
      SizedBox(height: spacing.lg),
      if (target != null || engine.hasPendingModuleCompletion) ...[
        KeyboardNavigationLabel(
          label: engine.hasPendingModuleCompletion
              ? 'Concluir módulo'
              : engine.completedCount == 0
              ? 'Começar curso'
              : 'Continuar curso',
          child: ElevatedButton.icon(
            autofocus: true,
            onPressed: engine.resume,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              engine.hasPendingModuleCompletion
                  ? 'Concluir módulo'
                  : engine.completedCount == 0
                  ? 'Começar curso'
                  : 'Continuar curso',
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        if (target != null) Text('Próxima missão: ${target.lesson.title}'),
      ] else
        Text(
          engine.completedCount == engine.exerciseCount
              ? 'Curso concluído! Abra um módulo para praticar novamente.'
              : 'Nenhum exercício pendente disponível. Você pode explorar os módulos e refazer atividades concluídas.',
        ),
      SizedBox(height: spacing.lg),
      for (final (index, module) in engine.course.modules.indexed)
        CourseNavigationTile(
          autofocus:
              target == null &&
              !engine.hasPendingModuleCompletion &&
              index == 0,
          title: module.title,
          description:
              '${module.lessons.where((lesson) => !engine.isOptionalLesson(lesson)).length} missões · Abrir módulo',
          onPressed: () => engine.openModule(module),
        ),
      SizedBox(height: spacing.md),
      KeyboardNavigationLabel(
        label: 'Rever introdução do curso',
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() => _courseIntroductionComplete = false);
            engine.openCourse();
          },
          icon: const Icon(Icons.replay),
          label: const Text('Rever introdução'),
        ),
      ),
    ];
  }

  List<Widget> _narrationControls(
    BuildContext context, {
    List<ContentAudioCue>? cues,
  }) {
    final spacing = context.courseTheme.spacing;
    final configuration = cues == null
        ? null
        : CourseAudioConfiguration(start: cues);
    final canReplay = configuration == null
        ? engine.canReplayNarration
        : engine.courseAudio.hasCues(configuration, CourseAudioEvent.start);

    if (!canReplay) return const [];

    Future<void> replay() => configuration == null
        ? engine.replayNarration()
        : engine.courseAudio.play(configuration, CourseAudioEvent.start);

    return [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: spacing.sm,
        children: [
          KeyboardNavigationLabel(
            label: 'Ouvir apresentação',
            child: OutlinedButton.icon(
              onPressed: () => unawaited(replay()),
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Ouvir apresentação'),
            ),
          ),
          KeyboardNavigationLabel(
            label: 'Parar áudio',
            child: TextButton(
              onPressed: engine.stopNarration,
              child: const Text('Parar áudio'),
            ),
          ),
        ],
      ),
      SizedBox(height: spacing.md),
    ];
  }

  List<Widget> _module(BuildContext context) {
    final spacing = context.courseTheme.spacing;
    return [
      if (engine.scene != null) ...[
        Text(engine.scene!.text),
        SizedBox(height: spacing.md),
      ],
      if (engine.isModuleReadyForCompletion) ...[
        KeyboardNavigationLabel(
          label: 'Concluir módulo',
          child: FilledButton(
            autofocus: true,
            onPressed: () => engine.openModuleCompletion(engine.module!),
            child: const Text('Concluir módulo'),
          ),
        ),
        SizedBox(height: spacing.md),
      ],
      for (final (index, lesson) in engine.module!.lessons.indexed)
        CourseNavigationTile(
          autofocus:
              !engine.isModuleReadyForCompletion &&
              engine.isLessonUnlocked(lesson) &&
              index == 0,
          title: lesson.title,
          description: !engine.isLessonUnlocked(lesson)
              ? 'Bloqueada · Conclua a missão anterior para continuar.'
              : engine.completedIn(lesson) == lesson.exercises.length
              ? 'Concluída · Praticar novamente'
              : engine.isOptionalLesson(lesson)
              ? 'Opcional · Jogar quando quiser'
              : engine.completedIn(lesson) > 0
              ? 'Em andamento · Continuar missão'
              : 'Disponível · Começar missão',
          earnedStars: engine.earnedStarsFor(lesson),
          completed: engine.isLessonCompleted(lesson),
          onPressed: engine.isLessonUnlocked(lesson)
              ? () => engine.openLesson(engine.module!, lesson)
              : null,
        ),
    ];
  }

  Widget? _missionFooter(BuildContext context) {
    final spacing = context.courseTheme.spacing;
    final lesson = engine.lesson!;
    final pending = engine.pendingIn(lesson);
    final completed = engine.completedIn(lesson);
    final target =
        pending ??
        (engine.isLessonCompleted(lesson)
            ? lesson.exercises
                  .where(
                    (exercise) => engine.isExerciseUnlocked(lesson, exercise),
                  )
                  .firstOrNull
            : null);
    if (target == null) return null;
    final label = pending == null
        ? 'Praticar missão novamente'
        : completed == 0
        ? 'Começar missão'
        : 'Continuar missão';
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.sm,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: KeyboardNavigationLabel(
              label: label,
              child: ElevatedButton.icon(
                autofocus: true,
                onPressed: () =>
                    engine.openExercise(engine.module!, lesson, target),
                icon: const Icon(Icons.play_arrow),
                label: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _lesson(BuildContext context) {
    final spacing = context.courseTheme.spacing;
    final lesson = engine.lesson!;
    final completed = engine.completedIn(lesson);
    final pending = engine.pendingIn(lesson);
    final following = engine.followingLesson;
    final firstAvailableIndex = lesson.exercises.indexWhere(
      (exercise) => engine.isExerciseUnlocked(lesson, exercise),
    );
    return [
      Text('${lesson.exercises.length} exercícios nesta missão'),
      SizedBox(height: spacing.sm),
      if (completed > 0) ...[
        DvxProgressIndicator(
          completed: completed,
          total: lesson.exercises.length,
        ),
        SizedBox(height: spacing.md),
      ],
      if (pending == null)
        Text(
          engine.isLessonCompleted(lesson)
              ? 'Missão concluída! Você pode praticar novamente.'
              : 'Conclua a missão anterior para liberar esta atividade.',
        ),
      SizedBox(height: spacing.md),
      ExpansionTile(
        key: PageStorageKey('mission-exercises-${lesson.id}'),
        title: const Text('Exercícios da missão'),
        children: [
          for (final (index, exercise) in lesson.exercises.indexed)
            CourseNavigationTile(
              autofocus: pending == null && index == firstAvailableIndex,
              title: '${index + 1}. ${exercise.title}',
              description: !engine.isExerciseUnlocked(lesson, exercise)
                  ? 'Conclua o exercício anterior para liberar.'
                  : engine.isCompleted(lesson, exercise)
                  ? 'Concluído · Refazer exercício'
                  : 'Iniciar exercício',
              completed: engine.isCompleted(lesson, exercise),
              onPressed: engine.isExerciseUnlocked(lesson, exercise)
                  ? () => engine.openExercise(engine.module!, lesson, exercise)
                  : null,
            ),
        ],
      ),
      if (following != null && engine.isLessonUnlocked(following.lesson))
        KeyboardNavigationLabel(
          label: 'Próxima missão: ${following.lesson.title}',
          child: OutlinedButton(
            onPressed: () =>
                engine.openLesson(following.module, following.lesson),
            child: Text('Próxima missão: ${following.lesson.title}'),
          ),
        ),
    ];
  }
}

final class _CourseIntroduction extends StatefulWidget {
  const _CourseIntroduction({
    required this.engine,
    required this.firstCharacter,
    required this.firstText,
    required this.firstCues,
    required this.secondCharacter,
    required this.secondText,
    required this.secondCues,
    required this.onComplete,
    required this.narrationControls,
  });

  final CourseJourneyEngine engine;
  final CourseCharacter firstCharacter;
  final String firstText;
  final List<ContentAudioCue> firstCues;
  final CourseCharacter secondCharacter;
  final String secondText;
  final List<ContentAudioCue> secondCues;
  final VoidCallback onComplete;
  final List<Widget> Function({List<ContentAudioCue>? cues}) narrationControls;

  @override
  State<_CourseIntroduction> createState() => _CourseIntroductionState();
}

final class _CourseIntroductionState extends State<_CourseIntroduction> {
  bool _showingSecondSpeaker = false;

  @override
  void initState() {
    super.initState();
    unawaited(_play(widget.firstCues));
  }

  Future<void> _play(List<ContentAudioCue> cues) async {
    await widget.engine.stopNarration();
    if (!mounted) return;
    await widget.engine.courseAudio.play(
      CourseAudioConfiguration(start: cues),
      CourseAudioEvent.start,
    );
  }

  void _continue() {
    if (!_showingSecondSpeaker) {
      setState(() => _showingSecondSpeaker = true);
      unawaited(_play(widget.secondCues));
      return;
    }
    unawaited(widget.engine.stopNarration());
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.courseTheme.spacing;
    final character = _showingSecondSpeaker
        ? widget.secondCharacter
        : widget.firstCharacter;
    final text = _showingSecondSpeaker ? widget.secondText : widget.firstText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: spacing.md,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  image: true,
                  label: character.imageDescription,
                  child: ExcludeSemantics(
                    child: ClipOval(
                      child: Image.asset(
                        character.imageAsset,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(width: 72, height: 72),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label: '${character.name} diz: $text',
                    child: ExcludeSemantics(
                      child: DvxGameCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                character.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            SizedBox(height: spacing.sm),
                            Text(text),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.lg),
            KeyboardNavigationLabel(
              label: _showingSecondSpeaker
                  ? 'Continuar para o curso'
                  : 'Continuar para a fala de ${widget.secondCharacter.name}',
              child: FilledButton(
                key: ValueKey(
                  _showingSecondSpeaker
                      ? 'continue-to-course'
                      : 'continue-to-${widget.secondCharacter.name}',
                ),
                autofocus: true,
                onPressed: _continue,
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
        ...widget.narrationControls(
          cues: _showingSecondSpeaker ? widget.secondCues : widget.firstCues,
        ),
      ],
    );
  }
}

final class _ModuleCompletion extends StatefulWidget {
  const _ModuleCompletion({required this.engine});

  final CourseJourneyEngine engine;

  @override
  State<_ModuleCompletion> createState() => _ModuleCompletionState();
}

final class _ModuleCompletionState extends State<_ModuleCompletion> {
  bool _saving = false;
  String? _error;

  Future<void> _continue() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.engine.completeModuleEvent();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível salvar a conclusão. Tente novamente.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final error = _error ?? engine.moduleCompletionError;
    final spacing = context.courseTheme.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CourseScene(
          scene: engine.completionEvent?.scene,
          character: engine.character,
          illustration: engine.illustration,
        ),
        for (final reward in engine.moduleRewardLabels)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: Text(reward),
          ),
        if (error != null) ...[
          Semantics(liveRegion: true, child: Text(error)),
          SizedBox(height: spacing.md),
        ],
        KeyboardNavigationLabel(
          label: 'Voltar ao módulo',
          child: FilledButton(
            autofocus: true,
            onPressed: _saving ? null : _continue,
            child: Text(_saving ? 'Salvando...' : 'Voltar ao módulo'),
          ),
        ),
        SizedBox(height: spacing.sm),
        KeyboardNavigationLabel(
          label: 'Ouvir cerimônia novamente',
          child: OutlinedButton.icon(
            onPressed: engine.replayModuleEvent,
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Ouvir cerimônia novamente'),
          ),
        ),
      ],
    );
  }
}
