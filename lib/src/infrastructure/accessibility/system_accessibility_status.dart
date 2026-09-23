import 'package:flutter/widgets.dart';

final class SystemAccessibilityStatus {
  const SystemAccessibilityStatus();

  bool get isAccessibleNavigationEnabled => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .accessibleNavigation;
}
