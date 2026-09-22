import '../../domain/progress/progress_repository.dart';
import '../../domain/progress/student_progress.dart';

final class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository({StudentProgress? initialProgress})
    : _progress = initialProgress ?? const StudentProgress();

  StudentProgress _progress;

  @override
  Future<StudentProgress> load() async => _progress;

  @override
  Future<void> save(StudentProgress progress) async {
    _progress = progress;
  }
}
