import 'progress_repository.dart';

final class StudentProfile {
  const StudentProfile({required this.id, required this.name});

  final String id;
  final String name;
}

abstract interface class ProfileRepository {
  Future<List<StudentProfile>> loadProfiles();

  Future<StudentProfile> createProfile(String name);

  Future<void> deleteProfile(String profileId);

  ProgressRepository progressFor(StudentProfile profile);
}
