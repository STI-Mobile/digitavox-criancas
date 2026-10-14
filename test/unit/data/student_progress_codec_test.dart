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
              tries: 3,
              exerciseAccuracies: <String, int>{
                'exercise-1': 97,
                'exercise-2': 100,
              },
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

    expect(document['schemaVersion'], 4);
    expect(settings['spokenFeedbackEnabled'], isFalse);
    expect(settings['themePreference'], 'highContrast');
    expect(
      codec.encode(progress),
      contains('"completedExerciseIds":["exercise-1","exercise-2"]'),
    );
    expect(
      codec.encode(progress),
      contains('"exerciseAccuracies":{"exercise-1":97,"exercise-2":100}'),
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
              tries: 2,
              exerciseAccuracies: <String, int>{
                'exercise-1': 96,
                'exercise-2': 99,
              },
            ),
            'lesson-2': LessonProgress(
              completedExerciseIds: <String>{'exercise-3'},
              stars: 1,
              tries: 1,
              exerciseAccuracies: <String, int>{'exercise-3': 100},
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
    expect(restored.courses['course-1']!.lessons['lesson-1']!.tries, 2);
    expect(
      restored.courses['course-1']!.lessons['lesson-1']!.exerciseAccuracies,
      {'exercise-1': 96, 'exercise-2': 99},
    );
    expect(
      restored.courses['course-1']!.lessons['lesson-1']!.completedExerciseIds,
      <String>{'exercise-1', 'exercise-2'},
    );
    expect(restored.settings.spokenFeedbackEnabled, isFalse);
    expect(restored.settings.themePreference, AppThemePreference.dark);
  });

  test('round trips measurements, ceremony events and rewards', () {
    final original = const StudentProgress()
        .recordExerciseResult(
          courseId: 'course',
          lessonId: 'mission',
          exerciseId: 'practice',
          accuracyPercent: 95,
          lessonAccuracyPercent: 90,
          lessonExerciseIds: const ['practice'],
          elapsedMilliseconds: 5000,
          totalInputs: 20,
          correctInputs: 19,
          errorPairs: const {'ç→l': 1},
        )
        .recordCourseEvent(
          courseId: 'course',
          eventId: 'launch',
          rewardIds: const ['bronze', 'blib-blub'],
        );
    final restored = codec.decode(codec.encode(original));
    final course = restored.courses['course']!;
    final stats = course.lessons['mission']!.exerciseStatistics['practice']!;
    expect(stats.elapsedMilliseconds, 5000);
    expect(stats.totalInputs, 20);
    expect(stats.correctInputs, 19);
    expect(stats.errorPairs, {'ç→l': 1});
    expect(course.completedEventIds, {'launch'});
    expect(course.unlockedRewardIds, {'bronze', 'blib-blub'});
    expect(codec.encode(restored), codec.encode(original));
  });

  test('migrates version 3 without claiming new rewards or measurements', () {
    final oldDocument = jsonDecode(
      codec.encode(
        const StudentProgress(
          courses: {
            'c': CourseProgress(
              lessons: {
                'l': LessonProgress(
                  completedExerciseIds: {'e'},
                  stars: 2,
                  tries: 3,
                  exerciseAccuracies: {'e': 95},
                ),
              },
            ),
          },
        ),
      ),
    ) as Map<String, dynamic>;
    oldDocument['schemaVersion'] = 3;
    final courses = oldDocument['progress']['courses'] as Map<String, dynamic>;
    final course = courses['c'] as Map<String, dynamic>;
    course.remove('completedEventIds');
    course.remove('unlockedRewardIds');
    (course['lessons']['l'] as Map<String, dynamic>).remove(
      'exerciseStatistics',
    );
    final restored = codec.decode(jsonEncode(oldDocument));
    expect(restored.courses['c']!.lessons['l']!.tries, 3);
    expect(restored.courses['c']!.lessons['l']!.exerciseAccuracies, {'e': 95});
    expect(restored.courses['c']!.lessons['l']!.exerciseStatistics, isEmpty);
    expect(restored.courses['c']!.completedEventIds, isEmpty);
    expect(restored.courses['c']!.unlockedRewardIds, isEmpty);
  });

  test('rejects inconsistent persisted statistics', () {
    final document = jsonDecode(
      codec.encode(
        const StudentProgress(
          courses: {
            'c': CourseProgress(
              lessons: {
                'l': LessonProgress(
                  exerciseStatistics: {
                    'e': ExerciseStatistics(totalInputs: 2, correctInputs: 2),
                  },
                ),
              },
            ),
          },
        ),
      ),
    ) as Map<String, dynamic>;
    document['progress']['courses']['c']['lessons']['l']['exerciseStatistics']['e']['correctInputs'] =
        3;
    expect(
      () => codec.decode(jsonEncode(document)),
      throwsA(isA<ProgressDataFormatException>()),
    );
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
          "schemaVersion": 99,
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

  test('migrates version 2 lessons with empty attempt statistics', () {
    final restored = codec.decode('''
      {
        "schemaVersion": 2,
        "progress": {
          "courses": {
            "course-1": {
              "lessons": {
                "lesson-1": {
                  "completedExerciseIds": ["exercise-1"],
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
    ''');

    final lesson = restored.courses['course-1']!.lessons['lesson-1']!;
    expect(lesson.tries, 0);
    expect(lesson.exerciseAccuracies, isEmpty);
    expect(lesson.completedExerciseIds, {'exercise-1'});
    expect(lesson.stars, 1);
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
