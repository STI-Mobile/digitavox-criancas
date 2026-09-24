import 'dart:async';

import 'package:flutter/material.dart';

import '../application/audio/audio_coordinator.dart';
import '../application/course_catalog_view_model.dart';
import '../application/course_journey_engine.dart';
import '../domain/content/course_catalog.dart';
import '../domain/progress/progress_repository.dart';
import '../domain/progress/student_progress.dart';
import '../infrastructure/feedback/system_exercise_sound_feedback.dart';
import 'course_journey_screen.dart';
import 'design_system/tokens/dvx_tokens.dart';

final class CourseHomeScreen extends StatefulWidget {
  const CourseHomeScreen({
    required this.courseCatalog,
    required this.progressRepository,
    required this.audioCoordinator,
    required this.onThemePreferenceChanged,
    super.key,
  });

  final CourseCatalog courseCatalog;
  final ProgressRepository progressRepository;
  final AudioCoordinator audioCoordinator;
  final ValueChanged<AppThemePreference> onThemePreferenceChanged;

  @override
  State<CourseHomeScreen> createState() => _CourseHomeScreenState();
}

final class _CourseHomeScreenState extends State<CourseHomeScreen>
    with WidgetsBindingObserver {
  late final CourseCatalogViewModel _catalog;
  CourseJourneyEngine? _engine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _catalog = CourseCatalogViewModel(
      courseCatalog: widget.courseCatalog,
      progressRepository: widget.progressRepository,
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _catalog.initialize();
    if (!mounted || _catalog.status != CourseCatalogStatus.ready) return;
    if (_catalog.courses.isEmpty) return;
    widget.onThemePreferenceChanged(_catalog.progress.settings.themePreference);
    setState(() {
      _engine = CourseJourneyEngine(
        course: _catalog.courses.first,
        catalog: _catalog,
        audio: widget.audioCoordinator,
        soundFeedback: const SystemExerciseSoundFeedback(),
      );
    });
    unawaited(_engine!.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(widget.audioCoordinator.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine?.dispose();
    _catalog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    if (engine != null) {
      return CourseJourneyScreen(
        engine: engine,
        onThemePreferenceChanged: widget.onThemePreferenceChanged,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Digitavox')),
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _catalog,
            builder: (context, _) {
              if (_catalog.status == CourseCatalogStatus.failure) {
                return Padding(
                  padding: const EdgeInsets.all(DvxSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(_catalog.errorMessage!),
                      ),
                      const SizedBox(height: DvxSpacing.md),
                      ElevatedButton(
                        onPressed: _initialize,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              if (_catalog.status == CourseCatalogStatus.ready &&
                  _catalog.courses.isEmpty) {
                return const Text('Nenhum curso disponível.');
              }
              return Semantics(
                label: 'Carregando conteúdo de demonstração',
                liveRegion: true,
                child: const CircularProgressIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
}
