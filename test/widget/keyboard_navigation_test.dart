import 'package:digitavox_criancas/src/presentation/keyboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'skips disabled controls, wraps and preserves modifier shortcuts',
    (tester) async {
      final announcements = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardNavigation(
            onAnnounce: (label) async => announcements.add(label),
            child: Scaffold(
              body: Column(
                children: [
                  KeyboardNavigationLabel(
                    label: 'Primeiro',
                    child: OutlinedButton(
                      autofocus: true,
                      onPressed: () {},
                      child: const Text('Primeiro'),
                    ),
                  ),
                  const KeyboardNavigationLabel(
                    label: 'Indisponível',
                    child: OutlinedButton(
                      onPressed: null,
                      child: Text('Indisponível'),
                    ),
                  ),
                  KeyboardNavigationLabel(
                    label: 'Último',
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Último'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(announcements, ['Último']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(announcements.last, 'Primeiro');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(announcements.last, 'Último');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(announcements.length, 3);
    },
  );
}
