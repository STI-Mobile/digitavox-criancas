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
    builder: (context, _) => Focus(
      key: ValueKey('keyboard-${engine.locationKey}'),
      autofocus: engine.stage != JourneyStage.exercise,
      onKeyEvent: _handleKeyEvent,
      child: PopScope(
        canPop: !engine.canGoBack,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) engine.back();
        },
        child: Builder(
          builder: (context) {
            final preference = engine.catalog.progress.settings.themePreference;
            final courseTheme = DvxCourseThemes.resolve(engine.course.themeId)
                .resolve(preference);
            return DvxGameScaffold(
              courseTheme: courseTheme,
              leading: engine.canGoBack
                  ? IconButton(
                      onPressed: engine.back,
                      tooltip: switch (engine.stage) {
                        JourneyStage.exercise => 'Voltar à lição',
                        JourneyStage.lesson => 'Voltar ao módulo',
                        _ => 'Voltar ao curso',
                      },
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
              title: switch (engine.stage) {
                JourneyStage.course => 'Digitavox',
                JourneyStage.module => 'Módulo',
                JourneyStage.lesson => 'Lição',
                JourneyStage.exercise => 'Exercício',
              },
              actions: [
                if (engine.currentAudio != null)
                  IconButton(
                    onPressed: engine.replayNarration,
                    tooltip: 'Ouvir novamente',
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
                DvxThemeSelector(
                  preference: preference,
                  onSelected: _selectTheme,
                ),
              ],
              body: Semantics(
                key: ValueKey(engine.locationKey),
                scopesRoute: true,
                namesRoute: true,
                label: engine.title,
                explicitChildNodes: true,
                child: FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: ListView(
                    key: PageStorageKey(engine.locationKey),
                    padding: const EdgeInsets.all(DvxSpacing.lg),
                    children: [
                      if (engine.canGoBack) ...[
                        Text(
                          [
                            engine.course.title,
                            if (engine.lesson != null) engine.module!.title,
                            if (engine.exercise != null) engine.lesson!.title,
                          ].join(' · '),
                        ),
                        const SizedBox(height: DvxSpacing.sm),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          engine.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: DvxSpacing.md),
                      CourseScene(
                        scene: engine.scene,
                        character: engine.character,
                      ),
                      if (engine.currentAudio != null) ...[
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: engine.replayNarration,
                              icon: const Icon(Icons.volume_up_outlined),
                              label: const Text('Ouvir novamente'),
                            ),
                            TextButton(
                              onPressed: engine.stopNarration,
                              child: const Text('Parar áudio'),
                            ),
                          ],
                        ),
                        const SizedBox(height: DvxSpacing.md),
                      ],
                      ...switch (engine.stage) {
                        JourneyStage.course => _course(),
                        JourneyStage.module => _module(),
                        JourneyStage.lesson => _lesson(),
                        JourneyStage.exercise => [
                          Text(
                            'Exercício ${engine.lesson!.exercises.indexOf(engine.exercise!) + 1} de ${engine.lesson!.exercises.length}',
                          ),
                          const SizedBox(height: DvxSpacing.md),
                          ExerciseScreen(
                            key: ValueKey(engine.exercise),
                            engine: engine,
                          ),
                        ],
                      },
                    ],
                  ),
                ),
              ),
            );
          },
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
      DvxStars(
        count: engine.catalog.progress.totalStars,
        color: DvxCourseThemes.resolve(engine.course.themeId)
            .resolve(engine.catalog.progress.settings.themePreference)
            .reward,
      ),
      const SizedBox(height: DvxSpacing.sm),
      Text(
        '${engine.completedCount} de ${engine.exerciseCount} exercícios concluídos',
      ),
      const SizedBox(height: DvxSpacing.lg),
      if (target != null) ...[
        ElevatedButton.icon(
          onPressed: engine.resume,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            engine.completedCount == 0 ? 'Começar curso' : 'Continuar curso',
          ),
        ),
        const SizedBox(height: DvxSpacing.sm),
        Text(
          'Próxima atividade: ${target.lesson.title} · ${target.exercise.title}',
        ),
      ] else
        Text(
          engine.completedCount == engine.exerciseCount
              ? 'Curso concluído! Abra um módulo para praticar novamente.'
              : 'Nenhum exercício pendente disponível. Você pode explorar os módulos e refazer atividades concluídas.',
        ),
      const SizedBox(height: DvxSpacing.lg),
      for (final (index, module) in engine.course.modules.indexed)
        CourseNavigationTile(
          title: 'Módulo ${index + 1} · ${module.title}',
          description: '${module.lessons.length} lições · Abrir módulo',
          onPressed: () => engine.openModule(module),
        ),
    ];
  }

  List<Widget> _module() => [
    for (final (index, lesson) in engine.module!.lessons.indexed)
      CourseNavigationTile(
        title: 'Lição ${index + 1} · ${lesson.title}',
        description:
            '${engine.completedIn(lesson)} de ${lesson.exercises.length} exercícios concluídos. '
            '${lesson.exercises.any(engine.isAvailable) ? 'Abrir lição' : 'Atividades ainda não disponíveis'}',
        completed: engine.completedIn(lesson) == lesson.exercises.length,
        onPressed: () => engine.openLesson(engine.module!, lesson),
      ),
  ];

  List<Widget> _lesson() {
    final lesson = engine.lesson!;
    final completed = engine.completedIn(lesson);
    final pending = engine.pendingIn(lesson);
    final following = engine.followingLesson;
    return [
      Text('$completed de ${lesson.exercises.length} exercícios concluídos'),
      const SizedBox(height: DvxSpacing.sm),
      DvxProgressIndicator(
        completed: completed,
        total: lesson.exercises.length,
      ),
      const SizedBox(height: DvxSpacing.lg),
      if (pending != null) ...[
        ElevatedButton.icon(
          onPressed: () => engine.openExercise(engine.module!, lesson, pending),
          icon: const Icon(Icons.play_arrow),
          label: Text(completed == 0 ? 'Começar lição' : 'Continuar lição'),
        ),
        const SizedBox(height: DvxSpacing.lg),
      ] else ...[
        Text(
          completed == lesson.exercises.length
              ? 'Lição concluída! Você pode refazer qualquer exercício.'
              : 'As atividades restantes desta lição ainda não estão disponíveis.',
        ),
        const SizedBox(height: DvxSpacing.lg),
      ],
      for (final (index, exercise) in lesson.exercises.indexed)
        CourseNavigationTile(
          title: '${index + 1}. ${exercise.title}',
          description:
              '${exercise.prompt}\n'
              '${!engine.isAvailable(exercise)
                  ? 'Ainda não disponível'
                  : engine.isCompleted(lesson, exercise)
                  ? 'Concluído · Refazer exercício'
                  : 'Iniciar exercício'}',
          completed: engine.isCompleted(lesson, exercise),
          onPressed: engine.isAvailable(exercise)
              ? () => engine.openExercise(engine.module!, lesson, exercise)
              : null,
        ),
      if (following != null)
        OutlinedButton(
          onPressed: () =>
              engine.openLesson(following.module, following.lesson),
          child: Text('Próxima lição: ${following.lesson.title}'),
        ),
      TextButton(
        onPressed: engine.openCourse,
        child: const Text('Voltar ao curso'),
      ),
    ];
  }
}
