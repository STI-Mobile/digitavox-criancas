import 'package:digitavox_criancas/src/app.dart';
import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/infrastructure/content/asset_course_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads the bundled demo catalog', (tester) async {
    await tester.pumpWidget(
      DigitavoxApp(
        courseCatalog: const AssetCourseCatalog(
          assetPath: 'assets/content/demo_course.json',
        ),
        progressRepository: InMemoryProgressRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Exploradores Espaciais'), findsOneWidget);
    expect(find.textContaining('CONTEÚDO DEMO'), findsOneWidget);
  });
}
