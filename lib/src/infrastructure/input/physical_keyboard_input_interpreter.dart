import 'package:flutter/services.dart';

final class PhysicalKeyboardInputInterpreter {
  const PhysicalKeyboardInputInterpreter();

  String? interpret(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return null;
    }

    final character = event.character;
    if (character == null || !_isSinglePrintableCharacter(character)) {
      return null;
    }
    return character;
  }
}

bool _isSinglePrintableCharacter(String value) {
  if (value.runes.length != 1) {
    return false;
  }
  final codePoint = value.runes.single;
  return codePoint >= 0x20 && codePoint != 0x7f;
}
