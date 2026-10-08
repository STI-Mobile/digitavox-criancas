import 'dart:async';

import 'package:flutter/material.dart';

import 'application/audio/audio_guidance.dart';
import 'application/course_audio_orchestrator.dart';
import 'domain/content/course_catalog.dart';
import 'domain/progress/profile_repository.dart';
import 'domain/progress/student_progress.dart';
import 'presentation/course_home_screen.dart';
import 'presentation/design_system/app_theme/dvx_app_theme.dart';
import 'presentation/profile_selection_screen.dart';

final class DigitavoxApp extends StatefulWidget {
  const DigitavoxApp({
    required this.courseCatalog,
    required this.profileRepository,
    required this.audioGuidance,
    super.key,
  });

  final CourseCatalog courseCatalog;
  final ProfileRepository profileRepository;
  final AudioGuidance audioGuidance;

  @override
  State<DigitavoxApp> createState() => _DigitavoxAppState();
}

final class _DigitavoxAppState extends State<DigitavoxApp> {
  AppThemePreference _themePreference = AppThemePreference.standard;
  StudentProfile? _selectedProfile;

  late final CourseAudioOrchestrator _courseAudio = CourseAudioOrchestrator(
    audioGuidance: widget.audioGuidance,
  );

  void _selectProfile(StudentProfile profile) {
    setState(() {
      _selectedProfile = profile;
      _themePreference = AppThemePreference.standard;
    });
  }

  @override
  void dispose() {
    unawaited(widget.audioGuidance.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _selectedProfile;

    return MaterialApp(
      title: 'Digitavox Crianças',
      debugShowCheckedModeBanner: false,
      theme: DvxAppTheme.resolve(_themePreference),
      themeAnimationDuration: const Duration(milliseconds: 200),
      home: profile == null
          ? ProfileSelectionScreen(
              profileRepository: widget.profileRepository,
              onProfileSelected: _selectProfile,
            )
          : CourseHomeScreen(
              courseCatalog: widget.courseCatalog,
              progressRepository: widget.profileRepository.progressFor(profile),
              courseAudio: _courseAudio,
              onThemePreferenceChanged: (preference) {
                setState(() => _themePreference = preference);
              },
            ),
    );
  }
}
