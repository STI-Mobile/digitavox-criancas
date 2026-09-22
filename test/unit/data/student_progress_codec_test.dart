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
        highContrastEnabled: true,
      ),
    );

    final document = jsonDecode(codec.encode(progress)) as Map<String, Object?>;
    final serializedProgress = document['progress']! as Map<String, Object?>;
    final settings = serializedProgress['settings']! as Map<String, Object?>;

    expect(document['schemaVersion'], 1);
    expect(settings['spokenFeedbackEnabled'], isFalse);
    expect(settings['highContrastEnabled'], isTrue);
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
        highContrastEnabled: false,
      ),
    );

    final restored = codec.decode(codec.encode(original));

    expect(restored.totalStars, 3);
    expect(
      restored.courses['course-1']!.lessons['lesson-1']!.completedExerciseIds,
      <String>{'exercise-1', 'exercise-2'},
    );
    expect(restored.settings.spokenFeedbackEnabled, isFalse);
    expect(restored.settings.highContrastEnabled, isFalse);
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
          "schemaVersion": 2,
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
              "highContrastEnabled": true
            }
          }
        }
      '''),
      throwsA(isA<ProgressDataFormatException>()),
    );
  });
}
