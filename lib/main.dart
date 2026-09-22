import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/persistence/in_memory_progress_repository.dart';
import 'src/infrastructure/content/asset_course_catalog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DigitavoxApp(
      courseCatalog: const AssetCourseCatalog(
        assetPath: 'assets/content/demo_course.json',
      ),
      progressRepository: InMemoryProgressRepository(),
    ),
  );
}
