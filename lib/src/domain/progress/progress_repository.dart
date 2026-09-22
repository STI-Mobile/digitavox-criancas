import 'student_progress.dart';

abstract interface class ProgressRepository {
  Future<StudentProgress> load();

  Future<void> save(StudentProgress progress);
}
