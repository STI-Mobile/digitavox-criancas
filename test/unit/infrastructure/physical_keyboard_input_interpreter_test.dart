import 'package:digitavox_criancas/src/infrastructure/input/physical_keyboard_input_interpreter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const interpreter = PhysicalKeyboardInputInterpreter();

  test('returns the character from a key-down event', () {
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyA,
      logicalKey: LogicalKeyboardKey.keyA,
      character: 'a',
      timeStamp: Duration.zero,
    );

    expect(interpreter.interpret(event), 'a');
  });

  test('ignores key-up and repeated events', () {
    const keyUp = KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.keyA,
      logicalKey: LogicalKeyboardKey.keyA,
      timeStamp: Duration.zero,
    );
    const keyRepeat = KeyRepeatEvent(
      physicalKey: PhysicalKeyboardKey.keyA,
      logicalKey: LogicalKeyboardKey.keyA,
      character: 'a',
      timeStamp: Duration.zero,
    );

    expect(interpreter.interpret(keyUp), isNull);
    expect(interpreter.interpret(keyRepeat), isNull);
  });

  test('ignores a key without a printable character', () {
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.arrowLeft,
      logicalKey: LogicalKeyboardKey.arrowLeft,
      timeStamp: Duration.zero,
    );

    expect(interpreter.interpret(event), isNull);
  });

  test('ignores a control character', () {
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.enter,
      logicalKey: LogicalKeyboardKey.enter,
      character: '\n',
      timeStamp: Duration.zero,
    );

    expect(interpreter.interpret(event), isNull);
  });
}
