import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('course code has a single audio boundary', () {
    final forbiddenSymbols = <String>[
      'Audio'
          'Coordinator',
      'ContentAudio'
          'Reference',
      'ContentAudio'
          'Service',
      'ExerciseSound'
          'Feedback',
      'SystemExerciseSound'
          'Feedback',
      'AudioplayersContentAudio'
          'Service',
    ];
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final symbol in forbiddenSymbols) {
        expect(
          source,
          isNot(contains(symbol)),
          reason: '${file.path} não deve reintroduzir $symbol.',
        );
      }
    }
  });

  test('audioplayers stays inside its guidance infrastructure adapter', () {
    final imports = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains(
            'package:audioplayers/audioplayers.dart',
          ),
        )
        .map((file) => file.path)
        .toList();

    expect(imports, <String>[
      'lib/src/infrastructure/audio/audioplayers_guidance_player.dart',
    ]);
  });

  test('course JSON uses only audioGuidance', () {
    final oldAudioProperty = RegExp(
      '"'
      'audio'
      '"\\s*:',
    );
    final jsonFiles = <File>[
      ...Directory('assets/content')
          .listSync(recursive: true)
          .whereType<File>(),
      ...Directory('docs/examples').listSync(recursive: true).whereType<File>(),
    ].where((file) => file.path.endsWith('.json'));

    for (final file in jsonFiles) {
      expect(
        file.readAsStringSync(),
        isNot(matches(oldAudioProperty)),
        reason: '${file.path} deve declarar somente audioGuidance.',
      );
    }
  });
}
