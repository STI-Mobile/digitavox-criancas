import 'package:digitavox_criancas/src/data/persistence/in_memory_progress_repository.dart';
import 'package:digitavox_criancas/src/domain/progress/profile_repository.dart';
import 'package:digitavox_criancas/src/domain/progress/progress_repository.dart';

/// App tests isolate profile selection from platform storage.
final class FakeProfileRepository implements ProfileRepository {
  final profiles = <StudentProfile>[
    const StudentProfile(id: 'cadete', name: 'Cadete'),
  ];
  final progress = InMemoryProgressRepository();
  @override
  Future<List<StudentProfile>> loadProfiles() async => List.of(profiles);
  @override
  Future<StudentProfile> createProfile(String name) async {
    final profile = StudentProfile(
      id: 'profile-${profiles.length}',
      name: name,
    );
    profiles.add(profile);
    return profile;
  }

  @override
  Future<void> deleteProfile(String profileId) async =>
      profiles.removeWhere((profile) => profile.id == profileId);
  @override
  ProgressRepository progressFor(StudentProfile profile) => progress;
}
