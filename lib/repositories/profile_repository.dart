import '../models/profile_model.dart';
import '../services/database_service.dart';

class ProfileRepository {
  final DatabaseService _database;

  ProfileRepository({DatabaseService? database})
    : _database = database ?? DatabaseService.instance;

  // Mengambil data profil berdasarkan ID pengguna.
  Future<ProfileModel?> getByUserId(int userId) async {
    final rows = await _database.query(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return ProfileModel.fromMap(rows.first);
  }

  // Menyimpan profil baru atau memperbarui profil lama.
  Future<void> save(ProfileModel profile) async {
    final existing = await _database.query(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [profile.userId],
    );

    final values = profile.toMap();

    if (existing.isEmpty) {
      await _database.insert('profiles', values);
    } else {
      await _database.update(
        'profiles',
        values,
        where: 'user_id = ?',
        whereArgs: [profile.userId],
      );
    }
  }
}
