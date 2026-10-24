import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/password_hasher.dart';

class UserRepository {
  final DatabaseService _database;

  UserRepository({DatabaseService? database})
    : _database = database ?? DatabaseService.instance;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw ArgumentError('Nama wajib diisi.');
    }

    if (!_isValidEmail(cleanEmail)) {
      throw ArgumentError('Format email tidak valid.');
    }

    if (password.length < 8) {
      throw ArgumentError('Password minimal 8 karakter.');
    }

    final existing = await _database.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanEmail],
    );

    if (existing.isNotEmpty) {
      throw StateError('Email sudah terdaftar.');
    }

    final passwordHash = await PasswordHasher.hash(password);

    final id = await _database.insert('users', {
      'name': cleanName,
      'email': cleanEmail,
      'password_hash': passwordHash,
      'created_at': DateTime.now().toIso8601String(),
    });

    return UserModel(id: id, name: cleanName, email: cleanEmail);
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final rows = await _database.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanEmail],
    );

    if (rows.isEmpty) return null;

    final user = rows.first;
    final storedHash = user['password_hash'] as String;

    final valid = await PasswordHasher.verify(password, storedHash);

    if (!valid) return null;

    return UserModel.fromMap(user);
  }

  Future<UserModel?> getById(int id) async {
    final rows = await _database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rows.isEmpty) return null;

    return UserModel.fromMap(rows.first);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}
