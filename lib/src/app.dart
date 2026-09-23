import 'dart:async';

import 'package:flutter/material.dart';

import 'application/audio/audio_coordinator.dart';
import 'domain/content/course_catalog.dart';
import 'domain/progress/progress_repository.dart';
import 'presentation/course_home_screen.dart';

final class DigitavoxApp extends StatefulWidget {
  const DigitavoxApp({
    required this.courseCatalog,
    required this.progressRepository,
    required this.audioCoordinator,
    super.key,
  });

  final CourseCatalog courseCatalog;
  final ProgressRepository progressRepository;
  final AudioCoordinator audioCoordinator;

  @override
  State<DigitavoxApp> createState() => _DigitavoxAppState();
}

final class _DigitavoxAppState extends State<DigitavoxApp> {
  @override
  void dispose() {
    unawaited(widget.audioCoordinator.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF071A40);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00D9FF),
      brightness: Brightness.dark,
      surface: background,
    );

    return MaterialApp(
      title: 'Digitavox Crianças',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: background,
        useMaterial3: true,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: CourseHomeScreen(
        courseCatalog: widget.courseCatalog,
        progressRepository: widget.progressRepository,
        audioCoordinator: widget.audioCoordinator,
      ),
    );
  }
}
