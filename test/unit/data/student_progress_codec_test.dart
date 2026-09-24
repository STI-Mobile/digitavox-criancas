import 'dart:convert';

import 'package:digitavox_criancas/src/data/persistence/student_progress_codec.dart';
import 'package:digitavox_criancas/src/domain/progress/student_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = StudentProgressCodec();

  test('serializes the complete versioned progress document', () {
    const progress = StudentProgress(
      courses: <String, CourseProgress>{
        'course-1': CourseProgress(
          lessons: <String, LessonProgress>{
            'lesson-1': LessonProgress(
              completedExerciseIds: <String>{'exercise-2', 'exercise-1'},
              stars: 2,
            ),
          },
        ),
      },
      settings: AppSettings(
        spokenFeedbackEnabled: false,
        themePreference: AppThemePreference.highContrast,
      ),
    );

    final document = jsonDecode(codec.encode(progress)) as Map<String, Object?>;
    final serializedProgress = document['progress']! as Map<String, Object?>;
    final settings = serializedProgress['settings']! as Map<String, Object?>;

    expect(document['schemaVersion'], 2);
    expect(settings['spokenFeedbackEnabled'], isFalse);
    expect(settings['themePreference'], 'highContrast');
    expect(
      codec.encode(progress),
      contains('"completedExerciseIds":["exercise-1","exercise-2"]'),
    );
  });

  test('round-trips courses, lessons, completions, stars and settings', () {
    const original = StudentProgress(
      courses: <String, CourseProgress>{
        'course-1': CourseProgress(
          lessons: <String, LessonProgress>{
            'lesson-1': LessonProgress(
              completedExerciseIds: <String>{'exercise-1', 'exercise-2'},
              stars: 2,
            ),
            'lesson-2': LessonProgress(
              completedExerciseIds: <String>{'exercise-3'},
              stars: 1,
            ),
          },
        ),
      },
      settings: AppSettings(
        spokenFeedbackEnabled: false,
        themePreference: AppThemePreference.dark,
      ),
    );

    final restored = codec.decode(codec.encode(original));

    expect(restored.totalStars, 3);
    expect(
      restored.courses['course-1']!.lessons['lesson-1']!.completedExerciseIds,
      <String>{'exercise-1', 'exercise-2'},
    );
    expect(restored.settings.spokenFeedbackEnabled, isFalse);
    expect(restored.settings.themePreference, AppThemePreference.dark);
  });

  test('rejects malformed JSON with a known format error', () {
    expect(
      () => codec.decode('{'),
      throwsA(isA<ProgressDataFormatException>()),
    );
  });

  test('rejects an unsupported schema version explicitly', () {
    expect(
      () => codec.decode('''
        {
          "schemaVersion": 3,
          "progress": {"courses": {}, "settings": {}}
        }
      '''),
      throwsA(isA<UnsupportedProgressSchemaException>()),
    );
  });

  test('rejects invalid progress values instead of coercing them', () {
    expect(
      () => codec.decode('''
        {
          "schemaVersion": 1,
          "progress": {
            "courses": {
              "course-1": {
                "lessons": {
                  "lesson-1": {
                    "completedExerciseIds": ["exercise-1", "exercise-1"],
                    "stars": 1
                  }
                }
              }
            },
            "settings": {
              "spokenFeedbackEnabled": true,
              "themePreference": "standard"
            }
          }
        }
      '''),
      throwsA(isA<ProgressDataFormatException>()),
    );
  });

  test('migrates the version 1 high contrast preference', () {
    final restored = codec.decode('''
      {
        "schemaVersion": 1,
        "progress": {
          "courses": {},
          "settings": {
            "spokenFeedbackEnabled": true,
            "highContrastEnabled": true
          }
        }
      }
    ''');

    expect(restored.settings.themePreference, AppThemePreference.highContrast);
  });

  test('rejects an unknown theme preference', () {
    expect(
      () => codec.decode('''
        {
          "schemaVersion": 2,
          "progress": {
            "courses": {},
            "settings": {
              "spokenFeedbackEnabled": true,
              "themePreference": "sepia"
            }
          }
        }
      '''),
      throwsA(isA<ProgressDataFormatException>()),
    );
  });
}
