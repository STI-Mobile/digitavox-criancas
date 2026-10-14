import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/course_journey_engine.dart';
import '../domain/progress/student_progress.dart';
import 'course_navigation_tile.dart';
import 'course_scene.dart';
import 'design_system/components/dvx_game_components.dart';
import 'design_system/course_theme/course_theme.dart';
import 'design_system/tokens/dvx_tokens.dart';
import 'exercise_screen.dart';
import 'keyboard_navigation.dart';

final class CourseJourneyScreen extends StatelessWidget {
  const CourseJourneyScreen({
    required this.engine,
    required this.onThemePreferenceChanged,
    super.key,
  });

  final CourseJourneyEngine engine;
  final ValueChanged<AppThemePreference> onThemePreferenceChanged;

  Future<void> _selectTheme(AppThemePreference preference) async {
    await engine.catalog.updateThemePreference(preference);
    onThemePreferenceChanged(preference);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        engine.canGoBack) {
      engine.back();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: engine,
    builder: (context, _) => KeyboardNavigation(
      key: ValueKey('keyboard-${engine.locationKey}'),
      onNavigate: () => unawaited(engine.stopNarration()),
      onAnnounce: engine.courseAudio.speakText,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: _handleKeyEvent,
        child: PopScope(
          canPop: !engine.canGoBack,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) engine.back();
          },
          child: Builder(
            builder: (context) {
              final preference =
                  engine.catalog.progress.settings.themePreference;
              final courseTheme = DvxCourseThemes.resolve(engine.course.themeId)
                  .resolve(preference);
              return DvxGameScaffold(
                courseTheme: courseTheme,
                bottomNavigationBar: engine.stage == JourneyStage.lesson
                    ? _missionFooter()
                    : null,
                leading: engine.canGoBack
                    ? KeyboardNavigationLabel(
                        label: switch (engine.stage) {
                          JourneyStage.exercise => 'Voltar à missão',
                          JourneyStage.lesson ||
                          JourneyStage.moduleCompletion => 'Voltar ao módulo',
                          _ => 'Voltar ao curso',
                        },
                        child: IconButton(
                          onPressed: engine.back,
                          tooltip: switch (engine.stage) {
                            JourneyStage.exercise => 'Voltar à missão',
                            JourneyStage.lesson ||
                            JourneyStage.moduleCompletion => 'Voltar ao módulo',
                            _ => 'Voltar ao curso',
                          },
                          icon: const Icon(Icons.arrow_back),
                        ),
                      )
                    : null,
                title: switch (engine.stage) {
                  JourneyStage.course => 'Digitavox',
                  JourneyStage.module => 'Módulo',
                  JourneyStage.lesson => 'Missão',
                  JourneyStage.exercise =>
                    engine.currentLessonCompleted
                        ? 'Missão concluída'
                        : engine.lesson!.title,
                  JourneyStage.moduleCompletion => 'Conclusão do módulo',
                },
                actions: engine.stage == JourneyStage.exercise
                    ? const <Widget>[]
                    : [
                        DvxThemeSelector(
                          preference: preference,
                          onSelected: _selectTheme,
                          onAnnounce: engine.courseAudio.speakText,
                        ),
                      ],
                body: Semantics(
                  key: ValueKey(engine.locationKey),
                  scopesRoute: true,
                  namesRoute: true,
                  label:
                      engine.stage == JourneyStage.exercise &&
                          engine.currentLessonCompleted
                      ? 'Missão concluída. ${engine.lesson!.title}'
                      : engine.title,
                  explicitChildNodes: true,
                  child: SingleChildScrollView(
                    key: PageStorageKey(engine.locationKey),
                    padding: const EdgeInsets.all(DvxSpacing.lg),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (engine.stage != JourneyStage.exercise) ...[
                              Semantics(
                                header: true,
                                child: Text(
                                  engine.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                              const SizedBox(height: DvxSpacing.md),
                            ],
                            if (engine.stage == JourneyStage.lesson) ...[
                              CourseScene(
                                scene: engine.scene,
                                character: engine.character,
                                illustration: engine.illustration,
                              ),
                              ..._narrationControls(),
                            ],
                            ...switch (engine.stage) {
                              JourneyStage.course => _course(),
                              JourneyStage.module => _module(),
                              JourneyStage.lesson => _lesson(),
                              JourneyStage.moduleCompletion => [
                                _ModuleCompletion(engine: engine),
                              ],
                              JourneyStage.exercise => [
                                ExerciseScreen(
                                  key: ValueKey(engine.session),
                                  engine: engine,
                                ),
                              ],
                            },
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  List<Widget> _course() {
    final target = engine.resumeTarget;
    return [
      if (engine.course.isDemo) ...[
        Semantics(
          label: 'Aviso: conteúdo de demonstração, não é conteúdo pedagógico definitivo.',
          child: const Text('DEMO'),
        ),
        const SizedBox(height: DvxSpacing.md),
      ],
      if (engine.scene != null)
        ExpansionTile(
          key: PageStorageKey('course-story-${engine.course.id}'),
          title: const Text('Apresentação do curso'),
          children: [
            Padding(
              padding: const EdgeInsets.all(DvxSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(engine.scene!.text),
                  if (engine.scene!.instruction.isNotEmpty) ...[
                    const SizedBox(height: DvxSpacing.md),
                    Text(engine.scene!.instruction),
                  ],
                ],
              ),
            ),
            ..._narrationControls(),
          ],
        ),
      const SizedBox(height: DvxSpacing.md),
      Text(
        '${engine.completedMissionCount} de ${engine.missionCount} missões concluídas',
      ),
      const SizedBox(height: DvxSpacing.lg),
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
        const SizedBox(height: DvxSpacing.sm),
        if (target != null) Text('Próxima missão: ${target.lesson.title}'),
      ] else
        Text(
          engine.completedCount == engine.exerciseCount
              ? 'Curso concluído! Abra um módulo para praticar novamente.'
              : 'Nenhum exercício pendente disponível. Você pode explorar os módulos e refazer atividades concluídas.',
        ),
      const SizedBox(height: DvxSpacing.lg),
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
    ];
  }

  List<Widget> _narrationControls() => [
    if (engine.canReplayNarration) ...[
      Wrap(
        spacing: DvxSpacing.sm,
        children: [
          KeyboardNavigationLabel(
            label: 'Ouvir apresentação',
            child: OutlinedButton.icon(
              onPressed: engine.replayNarration,
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
      const SizedBox(height: DvxSpacing.md),
    ],
  ];

  List<Widget> _module() => [
    if (engine.scene != null) ...[
      Text(engine.scene!.text),
      const SizedBox(height: DvxSpacing.md),
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
      const SizedBox(height: DvxSpacing.md),
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
        completed: engine.isLessonCompleted(lesson),
        onPressed: engine.isLessonUnlocked(lesson)
            ? () => engine.openLesson(engine.module!, lesson)
            : null,
      ),
  ];

  Widget? _missionFooter() {
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
        padding: const EdgeInsets.symmetric(
          horizontal: DvxSpacing.lg,
          vertical: DvxSpacing.sm,
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

  List<Widget> _lesson() {
    final lesson = engine.lesson!;
    final completed = engine.completedIn(lesson);
    final pending = engine.pendingIn(lesson);
    final following = engine.followingLesson;
    final firstAvailableIndex = lesson.exercises.indexWhere(
      (exercise) => engine.isExerciseUnlocked(lesson, exercise),
    );
    return [
      Text('${lesson.exercises.length} exercícios nesta missão'),
      const SizedBox(height: DvxSpacing.sm),
      if (completed > 0) ...[
        DvxProgressIndicator(
          completed: completed,
          total: lesson.exercises.length,
        ),
        const SizedBox(height: DvxSpacing.md),
      ],
      if (pending == null)
        Text(
          engine.isLessonCompleted(lesson)
              ? 'Missão concluída! Você pode praticar novamente.'
              : 'Conclua a missão anterior para liberar esta atividade.',
        ),
      const SizedBox(height: DvxSpacing.md),
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
            padding: const EdgeInsets.only(bottom: DvxSpacing.sm),
            child: Text(reward),
          ),
        if (error != null) ...[
          Semantics(liveRegion: true, child: Text(error)),
          const SizedBox(height: DvxSpacing.md),
        ],
        KeyboardNavigationLabel(
          label: 'Voltar ao módulo',
          child: FilledButton(
            autofocus: true,
            onPressed: _saving ? null : _continue,
            child: Text(_saving ? 'Salvando...' : 'Voltar ao módulo'),
          ),
        ),
        const SizedBox(height: DvxSpacing.sm),
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
