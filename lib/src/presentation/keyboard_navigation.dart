import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Menus use the same ordered, circular traversal for arrows and Tab.
/// Exercise input handles its own arrows before events reach this scope.
final class KeyboardNavigation extends StatelessWidget {
  const KeyboardNavigation({
    required this.child,
    this.onNavigate,
    this.onAnnounce,
    super.key,
  });

  final Widget child;
  final VoidCallback? onNavigate;
  final Future<void> Function(String)? onAnnounce;

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    policy: WidgetOrderTraversalPolicy(
      requestFocusCallback:
          (node, {alignmentPolicy, alignment, duration, curve}) {
            FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
              node,
              alignmentPolicy: alignmentPolicy,
              alignment: alignment,
              duration: duration,
              curve: curve,
            );
            final label = node.context
                ?.findAncestorWidgetOfExactType<KeyboardNavigationLabel>()
                ?.label;
            if (label != null && onAnnounce != null) {
              unawaited(onAnnounce!(label));
            }
          },
    ),
    child: FocusScope(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final keyboard = HardwareKeyboard.instance;
        if (keyboard.isControlPressed ||
            keyboard.isAltPressed ||
            keyboard.isMetaPressed) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        final backward =
            key == LogicalKeyboardKey.arrowUp ||
            (key == LogicalKeyboardKey.tab && keyboard.isShiftPressed);
        if (!backward &&
            key != LogicalKeyboardKey.arrowDown &&
            key != LogicalKeyboardKey.tab) {
          return KeyEventResult.ignored;
        }
        onNavigate?.call();
        final focused = FocusManager.instance.primaryFocus ?? node;
        if (backward) {
          focused.previousFocus();
        } else {
          focused.nextFocus();
        }
        return KeyEventResult.handled;
      },
      child: child,
    ),
  );
}

/// Supplies the spoken menu selection while retaining native button semantics.
final class KeyboardNavigationLabel extends InheritedWidget {
  const KeyboardNavigationLabel({
    required this.label,
    required super.child,
    super.key,
  });

  final String label;

  @override
  bool updateShouldNotify(KeyboardNavigationLabel oldWidget) =>
      label != oldWidget.label;
}
