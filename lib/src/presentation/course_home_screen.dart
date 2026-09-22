import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../application/course_catalog_view_model.dart';
import '../domain/content/course_catalog.dart';
import '../domain/progress/progress_repository.dart';

final class CourseHomeScreen extends StatefulWidget {
  const CourseHomeScreen({
    required this.courseCatalog,
    required this.progressRepository,
    super.key,
  });

  final CourseCatalog courseCatalog;
  final ProgressRepository progressRepository;

  @override
  State<CourseHomeScreen> createState() => _CourseHomeScreenState();
}

final class _CourseHomeScreenState extends State<CourseHomeScreen> {
  late final CourseCatalogViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CourseCatalogViewModel(
      courseCatalog: widget.courseCatalog,
      progressRepository: widget.progressRepository,
    );
    unawaited(_viewModel.initialize());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digitavox Crianças')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) => switch (_viewModel.status) {
            CourseCatalogStatus.initial ||
            CourseCatalogStatus.loading => const _LoadingContent(),
            CourseCatalogStatus.failure => _FailureContent(
              message: _viewModel.errorMessage ?? 'Erro desconhecido.',
              onRetry: _viewModel.initialize,
            ),
            CourseCatalogStatus.ready => _ReadyContent(viewModel: _viewModel),
          },
        ),
      ),
    );
  }
}

final class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Carregando conteúdo de demonstração',
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

final class _FailureContent extends StatelessWidget {
  const _FailureContent({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(liveRegion: true, child: Text(message)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ReadyContent extends StatelessWidget {
  const _ReadyContent({required this.viewModel});

  final CourseCatalogViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.courses.isEmpty) {
      return const Center(child: Text('Nenhum curso disponível.'));
    }

    final course = viewModel.courses.first;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Semantics(
            header: true,
            sortKey: const OrdinalSortKey(1),
            child: Text(
              course.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
          if (course.isDemo)
            Semantics(
              sortKey: const OrdinalSortKey(2),
              label: 'Aviso: conteúdo de demonstração, não é conteúdo pedagógico definitivo.',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CONTEÚDO DEMO — não representa o curso pedagógico final.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Semantics(
            sortKey: const OrdinalSortKey(3),
            liveRegion: true,
            label: '${viewModel.progress.totalStars} estrelas conquistadas',
            child: Text(
              'Estrelas: ${viewModel.progress.totalStars}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 20),
          ..._courseSections(course),
        ],
      ),
    );
  }

  Iterable<Widget> _courseSections(Course course) sync* {
    var sortOrder = 4.0;
    for (final module in course.modules) {
      yield Semantics(
        header: true,
        sortKey: OrdinalSortKey(sortOrder++),
        child: Text(
          module.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      );
      yield const SizedBox(height: 12);

      for (final lesson in module.lessons) {
        yield Semantics(
          header: true,
          sortKey: OrdinalSortKey(sortOrder++),
          child: Text(lesson.title, style: const TextStyle(fontSize: 19)),
        );
        yield const SizedBox(height: 8);

        for (final exercise in lesson.exercises) {
          final completed = viewModel.isExerciseCompleted(
            courseId: course.id,
            lessonId: lesson.id,
            exerciseId: exercise.id,
          );
          yield Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              sortKey: OrdinalSortKey(sortOrder++),
              button: true,
              label:
                  '${exercise.title}. ${exercise.prompt} '
                  '${completed ? 'Concluído' : 'Não concluído'}',
              child: ExcludeSemantics(
                child: ElevatedButton.icon(
                  onPressed: () => viewModel.completeExercise(
                    courseId: course.id,
                    lessonId: lesson.id,
                    exerciseId: exercise.id,
                  ),
                  icon: Icon(completed ? Icons.check_circle : Icons.play_arrow),
                  label: Text(
                    completed
                        ? '${exercise.title} — concluído'
                        : exercise.title,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
  }
}
