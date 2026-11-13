
import '../models/profile_model.dart';
import '../services/database_service.dart';

class ProfileRepository {
  final DatabaseService _database;

  ProfileRepository({DatabaseService? database})
      : _database = database ?? DatabaseService.instance;

  Future<ProfileModel?> getByUserId(int userId) async {
    final rows = await _database.query(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (rows.isEmpty) return null;

    return ProfileModel.fromMap(rows.first);
  }

  Future<void> save(ProfileModel profile) async {
    final existing = await getByUserId(profile.userId);
    final values = profile.toMap();

    if (existing == null) {
      await _database.insert('profiles', values);
    } else {
      values.remove('user_id');

      await _database.update(
        'profiles',
        values,
        where: 'user_id = ?',
        whereArgs: [profile.userId],
      );
    }
  }
}
