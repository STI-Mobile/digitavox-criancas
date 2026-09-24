import 'dart:async';

import 'package:flutter/material.dart';

import 'application/audio/audio_guidance.dart';
import 'application/course_audio_orchestrator.dart';
import 'domain/content/course_catalog.dart';
import 'domain/progress/progress_repository.dart';
import 'domain/progress/student_progress.dart';
import 'presentation/course_home_screen.dart';
import 'presentation/design_system/app_theme/dvx_app_theme.dart';

final class DigitavoxApp extends StatefulWidget {
  const DigitavoxApp({
    required this.courseCatalog,
    required this.progressRepository,
    required this.audioGuidance,
    super.key,
  });

  final CourseCatalog courseCatalog;
  final ProgressRepository progressRepository;
  final AudioGuidance audioGuidance;

  @override
  State<DigitavoxApp> createState() => _DigitavoxAppState();
}

final class _DigitavoxAppState extends State<DigitavoxApp> {
  AppThemePreference _themePreference = AppThemePreference.standard;
  late final CourseAudioOrchestrator _courseAudio = CourseAudioOrchestrator(
    audioGuidance: widget.audioGuidance,
  );

  @override
  void dispose() {
    unawaited(widget.audioGuidance.dispose());
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
        courseAudio: _courseAudio,
        onThemePreferenceChanged: (preference) {
          if (_themePreference == preference) return;
          setState(() => _themePreference = preference);
        },
      ),
    );
  }
}
