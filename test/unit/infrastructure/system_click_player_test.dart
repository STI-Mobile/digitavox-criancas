import 'package:digitavox_criancas/src/application/audio/audio_guidance_services.dart';
import 'package:digitavox_criancas/src/infrastructure/audio/system_click_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SystemClickPlayer player;
  late List<MethodCall> clicks;

  setUp(() {
    player = SystemClickPlayer();
    clicks = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemSound.play') clicks.add(call);
          return null;
        });
  });

  tearDown(() {
    player.stop();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'acerto dispara o mesmo clique nativo da implementação original',
    (tester) async {
      await player.play();
      expect(clicks, hasLength(1));
      expect(clicks.single.arguments, 'SystemSoundType.click');
    },
  );

  testWidgets('erro dispara dois cliques separados por 120 ms', (tester) async {
    final playback = player.play(doubleClick: true);
    await tester.pump();
    expect(clicks, hasLength(1));
    await tester.pump(const Duration(milliseconds: 119));
    expect(clicks, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    await playback;
    expect(clicks, hasLength(2));
    expect(
      clicks.map((call) => call.arguments),
      everyElement('SystemSoundType.click'),
    );
  });

  testWidgets('navegação cancela o segundo clique pendente', (tester) async {
    final playback = player.play(doubleClick: true);
    await tester.pump();
    player.stop();
    await tester.pump(const Duration(milliseconds: 120));
    await playback;
    expect(clicks, hasLength(1));
  });

  testWidgets('entrada nova substitui o pulso pendente do erro anterior', (
    tester,
  ) async {
    final oldPlayback = player.play(doubleClick: true);
    await tester.pump();
    await player.play();
    await tester.pump(const Duration(milliseconds: 120));
    await oldPlayback;
    expect(clicks, hasLength(2));
  });

  test('falha de plataforma é convertida para a fronteira de áudio', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async {
          throw PlatformException(code: 'unavailable');
        });
    await expectLater(player.play(), throwsA(isA<AudioServiceException>()));
  });
}
