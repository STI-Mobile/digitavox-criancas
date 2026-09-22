import 'package:digitavox_criancas/src/infrastructure/feedback/system_exercise_sound_feedback.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const feedback = SystemExerciseSoundFeedback();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('plays one click for a correct answer', () async {
    await feedback.playCorrect();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'SystemSound.play');
    expect(calls.single.arguments, 'SystemSoundType.click');
  });

  test('plays two clicks for an incorrect answer', () async {
    await feedback.playIncorrect();

    expect(calls, hasLength(2));
    expect(
      calls.map((call) => call.arguments),
      everyElement('SystemSoundType.click'),
    );
  });
}
