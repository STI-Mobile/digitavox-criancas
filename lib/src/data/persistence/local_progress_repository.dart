import '../../domain/progress/progress_repository.dart';
import '../../domain/progress/student_progress.dart';
import 'student_progress_codec.dart';

abstract interface class ProgressDocumentStore {
  Future<String?> read();

  Future<void> write(String document);
}

final class LocalProgressRepository implements ProgressRepository {
  const LocalProgressRepository({
    required this.store,
    this.codec = const StudentProgressCodec(),
  });

  final ProgressDocumentStore store;
  final StudentProgressCodec codec;

  @override
  Future<StudentProgress> load() async {
    final document = await store.read();
    if (document == null) {
      return const StudentProgress();
    }

    try {
      return codec.decode(document);
    } on ProgressDataFormatException {
      return const StudentProgress();
    }
  }

  @override
  Future<void> save(StudentProgress progress) =>
      store.write(codec.encode(progress));
}
