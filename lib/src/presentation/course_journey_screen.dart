import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/course_journey_engine.dart';
import 'course_navigation_tile.dart';
import 'course_scene.dart';
import 'exercise_screen.dart';

final class CourseJourneyScreen extends StatelessWidget {
  const CourseJourneyScreen({required this.engine, super.key});

  final CourseJourneyEngine engine;

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
        child: Scaffold(
          appBar: AppBar(
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
            title: Text(switch (engine.stage) {
              JourneyStage.course => 'Digitavox',
              JourneyStage.module => 'Módulo',
              JourneyStage.lesson => 'Lição',
              JourneyStage.exercise => 'Exercício',
            }),
          ),
          body: SafeArea(
            child: Semantics(
              key: ValueKey(engine.locationKey),
              scopesRoute: true,
              namesRoute: true,
              label: engine.title,
              explicitChildNodes: true,
              child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: ListView(
                  key: PageStorageKey(engine.locationKey),
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (engine.canGoBack) ...[
                      Text(
                        [
                          engine.course.title,
                          if (engine.lesson != null) engine.module!.title,
                          if (engine.exercise != null) engine.lesson!.title,
                        ].join(' · '),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        engine.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                    ],
                    ...switch (engine.stage) {
                      JourneyStage.course => _course(),
                      JourneyStage.module => _module(),
                      JourneyStage.lesson => _lesson(),
                      JourneyStage.exercise => [
                        Text(
                          'Exercício ${engine.lesson!.exercises.indexOf(engine.exercise!) + 1} de ${engine.lesson!.exercises.length}',
                        ),
                        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
      ],
      Semantics(
        liveRegion: true,
        label: '${engine.catalog.progress.totalStars} estrelas conquistadas',
        child: ExcludeSemantics(
          child: Text('★ ${engine.catalog.progress.totalStars}'),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${engine.completedCount} de ${engine.exerciseCount} exercícios concluídos',
      ),
      const SizedBox(height: 20),
      if (target != null) ...[
        ElevatedButton.icon(
          onPressed: engine.resume,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            engine.completedCount == 0 ? 'Começar curso' : 'Continuar curso',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Próxima atividade: ${target.lesson.title} · ${target.exercise.title}',
        ),
      ] else
        Text(
          engine.completedCount == engine.exerciseCount
              ? 'Curso concluído! Abra um módulo para praticar novamente.'
              : 'Nenhum exercício pendente disponível. Você pode explorar os módulos e refazer atividades concluídas.',
        ),
      const SizedBox(height: 24),
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
      const SizedBox(height: 8),
      ExcludeSemantics(
        child: LinearProgressIndicator(
          value: completed / lesson.exercises.length,
        ),
      ),
      const SizedBox(height: 20),
      if (pending != null) ...[
        ElevatedButton.icon(
          onPressed: () => engine.openExercise(engine.module!, lesson, pending),
          icon: const Icon(Icons.play_arrow),
          label: Text(completed == 0 ? 'Começar lição' : 'Continuar lição'),
        ),
        const SizedBox(height: 20),
      ] else ...[
        Text(
          completed == lesson.exercises.length
              ? 'Lição concluída! Você pode refazer qualquer exercício.'
              : 'As atividades restantes desta lição ainda não estão disponíveis.',
        ),
        const SizedBox(height: 20),
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
