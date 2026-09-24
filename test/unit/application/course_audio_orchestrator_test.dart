import 'package:digitavox_criancas/src/application/audio/audio_cue.dart';
import 'package:digitavox_criancas/src/application/course_audio_orchestrator.dart';
import 'package:digitavox_criancas/src/domain/content/course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/recording_audio_guidance.dart';

void main() {
  late CourseAudioOrchestrator orchestrator;

  setUp(() {
    orchestrator = CourseAudioOrchestrator(
      audioGuidance: RecordingAudioGuidance(),
    );
  });

  test('resolve configuração de fala para SpeechCue', () {
    final cues = orchestrator.resolve(
      const CourseAudioConfiguration(
        start: <ContentAudioCue>[
          ContentAudioCue(
            id: 'test-speech',
            type: ContentAudioCueType.speech,
            text: 'Teste de áudio.',
          ),
        ],
      ),
      CourseAudioEvent.start,
    );

    expect(cues, hasLength(1));
    expect(cues.single, isA<SpeechCue>());
    expect((cues.single as SpeechCue).text, 'Teste de áudio.');
  });

  test('preserva asset e text em SpeechCue', () {
    final cue =
        orchestrator
                .resolve(
                  const CourseAudioConfiguration(
                    start: <ContentAudioCue>[
                      ContentAudioCue(
                        id: 'asset-and-text',
                        type: ContentAudioCueType.speech,
                        text: 'Teste de áudio.',
                        asset: 'assets/audio/demo/test.wav',
                      ),
                    ],
                  ),
                  CourseAudioEvent.start,
                )
                .single
            as SpeechCue;

    expect(cue.text, 'Teste de áudio.');
    expect(cue.audioAsset, 'assets/audio/demo/test.wav');
  });

  test('mantém SpeechCue somente textual sem asset', () {
    final cue =
        orchestrator
                .resolve(
                  const CourseAudioConfiguration(
                    start: <ContentAudioCue>[
                      ContentAudioCue(
                        id: 'text-only',
                        type: ContentAudioCueType.speech,
                        text: 'Teste de início.',
                      ),
                    ],
                  ),
                  CourseAudioEvent.start,
                )
                .single
            as SpeechCue;

    expect(cue.text, 'Teste de início.');
    expect(cue.audioAsset, isNull);
  });

  test('resolve evento configurado como SfxCue', () {
    final cue = orchestrator
        .resolve(
          const CourseAudioConfiguration(
            incorrectInput: <ContentAudioCue>[
              ContentAudioCue(
                id: 'test-sfx',
                type: ContentAudioCueType.sfx,
                asset: 'assets/audio/demo/test.wav',
              ),
            ],
          ),
          CourseAudioEvent.incorrectInput,
        )
        .single;

    expect(cue, isA<SfxCue>());
    expect((cue as SfxCue).asset, 'assets/audio/demo/test.wav');
  });

  test('evento sem áudio configurado não produz cue', () {
    expect(orchestrator.resolve(null, CourseAudioEvent.completed), isEmpty);
    expect(
      orchestrator.resolve(
        const CourseAudioConfiguration(),
        CourseAudioEvent.completed,
      ),
      isEmpty,
    );
  });

  test('sequência declarada preserva tipo e ordem dos cues', () {
    final cues = orchestrator.resolve(
      const CourseAudioConfiguration(
        completed: <ContentAudioCue>[
          ContentAudioCue(
            id: 'first',
            type: ContentAudioCueType.speech,
            text: 'Teste concluído.',
          ),
          ContentAudioCue(
            id: 'second',
            type: ContentAudioCueType.sfx,
            asset: 'assets/audio/demo/test.wav',
          ),
          ContentAudioCue(
            id: 'third',
            type: ContentAudioCueType.speech,
            text: 'Fim da demonstração.',
          ),
        ],
      ),
      CourseAudioEvent.completed,
    );

    expect(cues.map((cue) => cue.id), <String>['first', 'second', 'third']);
    expect(cues, <Object>[isA<SpeechCue>(), isA<SfxCue>(), isA<SpeechCue>()]);
  });

  test('prompt visual e texto falado permanecem separados', () {
    final exercise = Exercise.fromJson(<String, Object?>{
      'id': 'separated-content',
      'title': 'Teste técnico',
      'type': 'key',
      'prompt': 'Entrada visual A.',
      'expectedInput': 'a',
      'audioGuidance': <String, Object?>{
        'start': <Object?>[
          <String, Object?>{
            'id': 'spoken-content',
            'type': 'speech',
            'text': 'Pressione a tecla A.',
          },
        ],
      },
    });
    final cue =
        orchestrator
                .resolve(exercise.audioGuidance, CourseAudioEvent.start)
                .single
            as SpeechCue;

    expect(exercise.prompt, 'Entrada visual A.');
    expect(cue.text, 'Pressione a tecla A.');
    expect(cue.text, isNot(exercise.prompt));
  });

  test('speaker é propagado somente como metadata', () {
    final cue =
        orchestrator
                .resolve(
                  const CourseAudioConfiguration(
                    start: <ContentAudioCue>[
                      ContentAudioCue(
                        id: 'metadata',
                        type: ContentAudioCueType.speech,
                        text: 'Teste.',
                        speaker: 'demo-speaker',
                      ),
                    ],
                  ),
                  CourseAudioEvent.start,
                )
                .single
            as SpeechCue;

    expect(cue.speaker, 'demo-speaker');
    expect(cue.text, 'Teste.');
    expect(cue.audioAsset, isNull);
  });

  test('conteúdo rejeita configuração de plataforma em um cue', () {
    expect(
      () => ContentAudioCue.fromJson(<String, Object?>{
        'id': 'invalid-platform-detail',
        'type': 'speech',
        'text': 'Teste.',
        'iosVoice': 'platform-specific',
      }),
      throwsA(isA<CourseContentFormatException>()),
    );
  });
}
