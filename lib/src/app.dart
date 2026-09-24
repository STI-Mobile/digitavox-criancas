import 'dart:async';

import 'package:flutter/material.dart';

import 'application/audio/audio_coordinator.dart';
import 'application/audio/audio_guidance_coordinator.dart';
import 'domain/content/course_catalog.dart';
import 'domain/progress/progress_repository.dart';
import 'domain/progress/student_progress.dart';
import 'presentation/course_home_screen.dart';
import 'presentation/design_system/app_theme/dvx_app_theme.dart';

final class DigitavoxApp extends StatefulWidget {
  const DigitavoxApp({
    required this.courseCatalog,
    required this.progressRepository,
    required this.audioCoordinator,
    this.audioGuidanceCoordinator,
    super.key,
  });

  final CourseCatalog courseCatalog;
  final ProgressRepository progressRepository;
  final AudioCoordinator audioCoordinator;
  final AudioGuidanceCoordinator? audioGuidanceCoordinator;

  @override
  State<DigitavoxApp> createState() => _DigitavoxAppState();
}

final class _DigitavoxAppState extends State<DigitavoxApp> {
  AppThemePreference _themePreference = AppThemePreference.standard;

  @override
  void dispose() {
    unawaited(widget.audioCoordinator.dispose());
    final audioGuidanceCoordinator = widget.audioGuidanceCoordinator;
    if (audioGuidanceCoordinator != null) {
      unawaited(audioGuidanceCoordinator.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digitavox Crianças',
      debugShowCheckedModeBanner: false,
      theme: DvxAppTheme.resolve(_themePreference),
      themeAnimationDuration: const Duration(milliseconds: 200),
      home: CourseHomeScreen(
        courseCatalog: widget.courseCatalog,
        progressRepository: widget.progressRepository,
        audioCoordinator: widget.audioCoordinator,
        onThemePreferenceChanged: (preference) {
          if (_themePreference == preference) return;
          setState(() => _themePreference = preference);
        },
      ),
    );
  }
}
