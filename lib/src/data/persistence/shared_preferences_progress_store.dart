import 'package:shared_preferences/shared_preferences.dart';

import 'local_progress_repository.dart';

final class SharedPreferencesProgressStore implements ProgressDocumentStore {
  SharedPreferencesProgressStore({
    this.storageKey = 'digitavox.student_progress',
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final String storageKey;
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(storageKey);

  @override
  Future<void> write(String document) =>
      _preferences.setString(storageKey, document);
}
