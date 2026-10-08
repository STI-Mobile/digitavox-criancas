import 'dart:convert';

import '../../domain/progress/profile_repository.dart';
import '../../domain/progress/progress_repository.dart';
import 'local_progress_repository.dart';

final class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({
    required this.profilesStore,
    required this.progressStoreFor,
  });

  final ProgressDocumentStore profilesStore;
  final ProgressDocumentStore Function(String profileId) progressStoreFor;

  @override
  Future<List<StudentProfile>> loadProfiles() async {
    final document = await profilesStore.read();
    if (document == null) return const [];

    try {
      final decoded = jsonDecode(document);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map(
            (item) => StudentProfile(
              id: item['id'] as String,
              name: item['name'] as String,
            ),
          )
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Future<StudentProfile> createProfile(String name) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'o nome não pode ser vazio');
    }

    final profiles = await loadProfiles();
    final profile = StudentProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalizedName,
    );

    await profilesStore.write(
      jsonEncode(
        [...profiles, profile]
            .map((item) => {'id': item.id, 'name': item.name})
            .toList(growable: false),
      ),
    );

    return profile;
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    final profiles = await loadProfiles();
    final remaining = profiles
        .where((profile) => profile.id != profileId)
        .toList(growable: false);

    await profilesStore.write(
      jsonEncode(
        remaining
            .map((item) => {'id': item.id, 'name': item.name})
            .toList(growable: false),
      ),
    );
  }

  @override
  ProgressRepository progressFor(StudentProfile profile) {
    return LocalProgressRepository(store: progressStoreFor(profile.id));
  }
}
